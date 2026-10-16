/* ###
 * IP: GHIDRA
 *
 * Targeted Analysis Automation Script for ARM64 iOS Binary (Phase 1.4.1)
 * Target Application: Waze iOS (com.waze.iphone v5.22.0)
 * Architecture: ARM64 (Little Endian, 64-bit)
 * Environment: Ghidra 12.1.2 Headless Analyzer / OpenJDK 27 / Arch Linux
 *
 * Description:
 *   Performs reproducible scoped disassembly, independent Objective-C runtime
 *   metadata resolution, function boundary auditing (contiguous ranges and gaps),
 *   control-flow graph (CFG) reconstruction, and decompilation verification.
 *   Avoids hardcoded selector assumptions by parsing Mach-O relative method lists
 *   and class metadata directly from program memory.
 */

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.mem.Memory;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.*;
import ghidra.app.decompiler.*;
import ghidra.program.model.block.*;
import java.util.*;

public class TargetAnalysis extends GhidraScript {

    public static class TargetSpec {
        final long address;
        final String expectedClass;
        final String expectedSelector;
        final String expectedTypeSignature;

        TargetSpec(long address, String expectedClass, String expectedSelector, String expectedTypeSignature) {
            this.address = address;
            this.expectedClass = expectedClass;
            this.expectedSelector = expectedSelector;
            this.expectedTypeSignature = expectedTypeSignature;
        }
    }

    public static class ObjcMethodMeta {
        final String className;
        final String selector;
        final String typeEncoding;
        final long methodListAddress;
        final long selRefAddress;
        final long rawImpAddress;

        ObjcMethodMeta(String className, String selector, String typeEncoding,
                       long methodListAddress, long selRefAddress, long rawImpAddress) {
            this.className = className;
            this.selector = selector;
            this.typeEncoding = typeEncoding;
            this.methodListAddress = methodListAddress;
            this.selRefAddress = selRefAddress;
            this.rawImpAddress = rawImpAddress;
        }
    }

    private static final TargetSpec[] TARGETS = {
        new TargetSpec(0x10001a718L, "AlternateRoutesStateMachineBridge", "applyRouteUpdateWithRouteUpdateProtos:", "v24@0:8@16"),
        new TargetSpec(0x1000d4b08L, "MainCanvasViewHolder", "init", "@16@0:8"),
        new TargetSpec(0x1000d4c6cL, "MainCanvasViewHolder", "makeGenericCanvasActivator", "@16@0:8"),
        new TargetSpec(0x100102264L, "NavigationGuidanceReducerBridge", "distanceToCrossSegmentWith:", "q24@0:8q16"),
        new TargetSpec(0x1000a1d28L, "WZWazeLocationServiceBridge", "currentSpeed", "@16@0:8")
    };

    private long unchainPointer(long val) {
        if (val == 0) return 0;
        if ((val & 0xffffffff00000000L) == 0x100000000L) return val;
        long offset = val & 0xfffffffffL;
        if (offset > 0) return 0x100000000L + offset;
        return val;
    }

    private String readNullTerminatedString(Memory mem, long addr) {
        if (addr == 0) return null;
        try {
            StringBuilder sb = new StringBuilder();
            Address a = toAddr(addr);
            for (int i = 0; i < 512; i++) {
                byte b = mem.getByte(a.add(i));
                if (b == 0) break;
                sb.append((char) b);
            }
            return sb.toString();
        } catch (Exception e) {
            return null;
        }
    }

    private Map<Long, ObjcMethodMeta> buildObjcMethodIndex(Memory mem) {
        Map<Long, ObjcMethodMeta> map = new HashMap<>();

        // 1. Index primary classes via __objc_classlist
        MemoryBlock clBlock = mem.getBlock("__objc_classlist");
        if (clBlock != null) {
            long clStart = clBlock.getStart().getOffset();
            long clEnd = clBlock.getEnd().getOffset();
            int classCount = (int) ((clEnd - clStart + 1) / 8);

            for (int i = 0; i < classCount; i++) {
                try {
                    long clsPtr = unchainPointer(mem.getLong(toAddr(clStart + i * 8)));
                    if (clsPtr == 0) continue;

                    // Check both instance methods and metaclass methods
                    long[] classNodes = new long[2];
                    classNodes[0] = clsPtr;
                    classNodes[1] = unchainPointer(mem.getLong(toAddr(clsPtr))); // isa

                    for (long node : classNodes) {
                        if (node == 0) continue;
                        long bits = mem.getLong(toAddr(node + 0x20));
                        long roPtr = unchainPointer(bits & 0x7ffffffffff8L);
                        if (roPtr == 0) continue;

                        long namePtr = unchainPointer(mem.getLong(toAddr(roPtr + 0x18)));
                        long methListPtr = unchainPointer(mem.getLong(toAddr(roPtr + 0x20)));
                        if (namePtr == 0 || methListPtr == 0) continue;

                        String clsName = readNullTerminatedString(mem, namePtr);
                        if (clsName == null) continue;

                        indexMethodList(mem, methListPtr, clsName, map);
                    }
                } catch (Exception ignored) {
                }
            }
        }

        // 2. Index category methods via __objc_catlist
        MemoryBlock catBlock = mem.getBlock("__objc_catlist");
        if (catBlock != null) {
            long catStart = catBlock.getStart().getOffset();
            long catEnd = catBlock.getEnd().getOffset();
            int catCount = (int) ((catEnd - catStart + 1) / 8);

            for (int i = 0; i < catCount; i++) {
                try {
                    long catPtr = unchainPointer(mem.getLong(toAddr(catStart + i * 8)));
                    if (catPtr == 0) continue;

                    long catNamePtr = unchainPointer(mem.getLong(toAddr(catPtr)));
                    long clsPtr = unchainPointer(mem.getLong(toAddr(catPtr + 8)));
                    long instMethListPtr = unchainPointer(mem.getLong(toAddr(catPtr + 16)));
                    long clsMethListPtr = unchainPointer(mem.getLong(toAddr(catPtr + 24)));

                    String clsName = null;
                    if (clsPtr != 0) {
                        long bits = mem.getLong(toAddr(clsPtr + 0x20));
                        long roPtr = unchainPointer(bits & 0x7ffffffffff8L);
                        if (roPtr != 0) {
                            long namePtr = unchainPointer(mem.getLong(toAddr(roPtr + 0x18)));
                            clsName = readNullTerminatedString(mem, namePtr);
                        }
                    }
                    if (clsName == null) {
                        clsName = "Category_" + readNullTerminatedString(mem, catNamePtr);
                    }

                    if (instMethListPtr != 0) indexMethodList(mem, instMethListPtr, clsName, map);
                    if (clsMethListPtr != 0) indexMethodList(mem, clsMethListPtr, clsName, map);
                } catch (Exception ignored) {
                }
            }
        }

        return map;
    }

    private void indexMethodList(Memory mem, long methListPtr, String clsName, Map<Long, ObjcMethodMeta> map) {
        try {
            int flags_entsize = mem.getInt(toAddr(methListPtr));
            int mCount = mem.getInt(toAddr(methListPtr + 4));
            boolean isRelative = (flags_entsize & 0x80000000) != 0 || (flags_entsize & 0xffff) == 12;
            int entsize = flags_entsize & 0xffff;

            if (isRelative) {
                long entryStart = methListPtr + 8;
                for (int m = 0; m < mCount; m++) {
                    long cur = entryStart + m * 12;
                    int nameOff = mem.getInt(toAddr(cur));
                    int typeOff = mem.getInt(toAddr(cur + 4));
                    int impOff = mem.getInt(toAddr(cur + 8));

                    long imp = cur + 8 + impOff;
                    long selRef = cur + nameOff;
                    long selPtrRaw = mem.getLong(toAddr(selRef));
                    long selPtr = unchainPointer(selPtrRaw);
                    String sel = readNullTerminatedString(mem, selPtr);
                    String type = readNullTerminatedString(mem, cur + 4 + typeOff);

                    if (sel != null && type != null) {
                        map.put(imp, new ObjcMethodMeta(clsName, sel, type, methListPtr, selRef, imp));
                    }
                }
            } else if (entsize == 24) {
                // Traditional 64-bit method list (name, types, imp: 3x 8-byte pointers)
                long entryStart = methListPtr + 8;
                for (int m = 0; m < mCount; m++) {
                    long cur = entryStart + m * 24;
                    long namePtr = unchainPointer(mem.getLong(toAddr(cur)));
                    long typePtr = unchainPointer(mem.getLong(toAddr(cur + 8)));
                    long imp = unchainPointer(mem.getLong(toAddr(cur + 16)));

                    String sel = readNullTerminatedString(mem, namePtr);
                    String type = readNullTerminatedString(mem, typePtr);

                    if (sel != null && type != null) {
                        map.put(imp, new ObjcMethodMeta(clsName, sel, type, methListPtr, cur, imp));
                    }
                }
            }
        } catch (Exception ignored) {
        }
    }

    @Override
    public void run() throws Exception {
        println("================================================================================");
        println("       GHIDRA TARGET ANALYSIS & OBJECTIVE-C METADATA VALIDATION (PHASE 1.4.1)   ");
        println("================================================================================");
        println("Program:         " + currentProgram.getName());
        println("Language ID:     " + currentProgram.getLanguageID());
        println("Image Base:      " + currentProgram.getImageBase());
        println("Target Count:    " + TARGETS.length + " ARM64 application routines");
        println("--------------------------------------------------------------------------------");

        Memory mem = currentProgram.getMemory();
        Listing listing = currentProgram.getListing();
        BasicBlockModel bbModel = new BasicBlockModel(currentProgram);

        // Task 2: Build independent Objective-C metadata index
        long indexStartMs = System.currentTimeMillis();
        Map<Long, ObjcMethodMeta> objcMap = buildObjcMethodIndex(mem);
        long indexElapsedMs = System.currentTimeMillis() - indexStartMs;
        println("[OBJC INDEX] Scanned Objective-C metadata structures: " + objcMap.size() +
                " methods indexed in " + indexElapsedMs + " ms.");
        println("--------------------------------------------------------------------------------");

        DecompInterface decompiler = new DecompInterface();
        decompiler.openProgram(currentProgram);

        int totalTargets = TARGETS.length;
        int totalDisasmSuccess = 0;
        int totalFuncSuccess = 0;
        int totalMetaVerified = 0;
        int totalDecompSuccess = 0;

        long totalDisasmDurationMs = 0;
        long totalDecompDurationMs = 0;

        for (int idx = 0; idx < TARGETS.length; idx++) {
            TargetSpec spec = TARGETS[idx];
            Address entry = toAddr(spec.address);

            println("\n--------------------------------------------------------------------------------");
            println(String.format("TARGET %d/%d: 0x%x [Expected: %s::%s]",
                    (idx + 1), totalTargets, spec.address, spec.expectedClass, spec.expectedSelector));
            println("--------------------------------------------------------------------------------");

            // 1. Memory block and executable section check
            MemoryBlock block = mem.getBlock(entry);
            boolean isExec = (block != null && block.isExecute());
            String blockName = (block != null) ? block.getName() : "UNMAPPED";
            println("  1. Memory Section:       " + blockName + " (Executable: " + isExec + ")");
            if (!isExec) {
                println("     [FATAL] Address does not reside in an executable section. Skipping target.");
                continue;
            }

            // 2. Independent Objective-C Metadata Verification (Task 2)
            ObjcMethodMeta meta = objcMap.get(spec.address);
            if (meta != null) {
                boolean classMatches = spec.expectedClass.equals(meta.className);
                boolean selMatches = spec.expectedSelector.equals(meta.selector);
                boolean typeMatches = spec.expectedTypeSignature.equals(meta.typeEncoding);

                println("  2. ObjC Metadata:        INDEPENDENT RESOLUTION AVAILABLE");
                println("     - Owning Class:       " + meta.className + (classMatches ? " [MATCH]" : " [MISMATCH]"));
                println("     - Selector Name:      " + meta.selector + (selMatches ? " [MATCH]" : " [MISMATCH]"));
                println("     - Type Encoding:      " + meta.typeEncoding + (typeMatches ? " [MATCH]" : " [MISMATCH]"));
                println(String.format("     - Method Table Entry: 0x%x (MethList: 0x%x, SelRef: 0x%x)",
                        meta.rawImpAddress, meta.methodListAddress, meta.selRefAddress));

                if (classMatches && selMatches && typeMatches) {
                    println("     - Verification Status: VERIFIED");
                    totalMetaVerified++;
                } else {
                    println("     - Verification Status: UNVERIFIED (Signature mismatch)");
                }
            } else {
                println("  2. ObjC Metadata:        NO ENTRY IN METHOD TABLES");
                println("     - Verification Status: UNVERIFIED");
            }

            // 3. Disassembly & Timing (Task 3)
            long disasmStartMs = System.currentTimeMillis();
            Instruction inst = getInstructionAt(entry);
            if (inst == null) {
                disassemble(entry);
                inst = getInstructionAt(entry);
            }
            long disasmDurationMs = System.currentTimeMillis() - disasmStartMs;
            totalDisasmDurationMs += disasmDurationMs;

            if (inst == null) {
                println("  3. Disassembly:          FAILED (" + disasmDurationMs + " ms)");
                continue;
            }
            totalDisasmSuccess++;
            println("  3. Disassembly:          SUCCESS (" + disasmDurationMs + " ms, Entry Instruction: " + inst.toString() + ")");

            // 4. Function Creation and Boundary Audit (Task 1 & Task 3)
            Function func = getFunctionAt(entry);
            if (func == null) {
                String funcName = (meta != null) ?
                        meta.className + "_" + meta.selector.replaceAll("[:_]", "_") :
                        "sub_" + Long.toHexString(spec.address);
                func = createFunction(entry, funcName);
            }

            if (func == null) {
                println("  4. Function Creation:    FAILED (Unable to establish function model)");
                continue;
            }
            totalFuncSuccess++;
            println("  4. Function Creation:    SUCCESS (Symbol: " + func.getName() + ")");

            AddressSetView body = func.getBody();
            Address minAddr = body.getMinAddress();
            Address maxAddr = body.getMaxAddress();
            long totalSpanBytes = maxAddr.getOffset() - minAddr.getOffset() + 1;
            long bodyBytes = body.getNumAddresses();

            AddressRangeIterator rangeIt = body.getAddressRanges();
            List<AddressRange> ranges = new ArrayList<>();
            while (rangeIt.hasNext()) {
                ranges.add(rangeIt.next());
            }

            List<String> gaps = new ArrayList<>();
            for (int r = 0; r < ranges.size() - 1; r++) {
                Address gStart = ranges.get(r).getMaxAddress().add(1);
                Address gEnd = ranges.get(r + 1).getMinAddress().subtract(1);
                long gSize = gEnd.getOffset() - gStart.getOffset() + 1;
                gaps.add(String.format("0x%x - 0x%x (%d bytes)", gStart.getOffset(), gEnd.getOffset(), gSize));
            }

            boolean isContiguous = (ranges.size() == 1);
            println("  5. Function Boundaries:");
            println(String.format("     - Inclusive Span:     0x%x - 0x%x (%d bytes)",
                    minAddr.getOffset(), maxAddr.getOffset(), totalSpanBytes));
            println("     - Body Byte Count:    " + bodyBytes + " bytes");
            println("     - Contiguous Layout:  " + (isContiguous ? "YES (1 range)" : "NO (" + ranges.size() + " ranges, " + gaps.size() + " gaps)"));

            for (int r = 0; r < ranges.size(); r++) {
                AddressRange ar = ranges.get(r);
                println(String.format("       * Range %d:         0x%x - 0x%x (%d bytes)",
                        r, ar.getMinAddress().getOffset(), ar.getMaxAddress().getOffset(), ar.getLength()));
            }

            if (!gaps.isEmpty()) {
                println("     - Excluded Gaps:");
                for (int g = 0; g < gaps.size(); g++) {
                    println("       * Gap " + g + ":           " + gaps.get(g));
                }
            }

            // 5. Instruction & CFG Counts (Task 1 & Task 3)
            InstructionIterator instIter = listing.getInstructions(body, true);
            int instructionCount = 0;
            int directCallCount = 0;
            int indirectCallCount = 0;
            int returnCount = 0;
            List<String> callees = new ArrayList<>();

            while (instIter.hasNext()) {
                Instruction cur = instIter.next();
                instructionCount++;
                FlowType flow = cur.getFlowType();

                if (flow.isCall()) {
                    Address[] flows = cur.getFlows();
                    if (flows != null && flows.length > 0) {
                        directCallCount++;
                        for (Address targetFlow : flows) {
                            Function calleeFunc = getFunctionAt(targetFlow);
                            String cName = (calleeFunc != null) ? calleeFunc.getName() : "sub_" + targetFlow;
                            callees.add(String.format("0x%x -> BL 0x%x (%s)", cur.getAddress().getOffset(), targetFlow.getOffset(), cName));
                        }
                    } else {
                        indirectCallCount++;
                        callees.add(String.format("0x%x -> %s [INDIRECT]", cur.getAddress().getOffset(), cur.toString()));
                    }
                } else if (flow.isTerminal()) {
                    returnCount++;
                }
            }

            CodeBlockIterator bbIter = bbModel.getCodeBlocksContaining(body, monitor);
            int basicBlockCount = 0;
            while (bbIter.hasNext()) {
                bbIter.next();
                basicBlockCount++;
            }

            println("  6. Flow & Graph Metrics:");
            println("     - Instruction Count:  " + instructionCount);
            println("     - CFG Basic Blocks:   " + basicBlockCount);
            println("     - Direct Calls (BL):  " + directCallCount);
            println("     - Indirect Calls (BLR): " + indirectCallCount);
            println("     - Terminal Exits (RET): " + returnCount);

            // 6. Decompilation & Warnings (Task 3)
            long decompStartMs = System.currentTimeMillis();
            DecompileResults results = decompiler.decompileFunction(func, 45, monitor);
            long decompDurationMs = System.currentTimeMillis() - decompStartMs;
            totalDecompDurationMs += decompDurationMs;

            boolean decompSuccess = results.decompileCompleted();
            List<String> warnings = new ArrayList<>();

            String err = results.getErrorMessage();
            if (err != null && !err.trim().isEmpty()) {
                warnings.add("Decompiler message: " + err.trim());
            }

            if (decompSuccess && results.getDecompiledFunction() != null) {
                totalDecompSuccess++;
                String cCode = results.getDecompiledFunction().getC();
                int lineCount = cCode.split("\n").length;

                for (String line : cCode.split("\n")) {
                    if (line.contains("WARNING:")) {
                        warnings.add(line.trim());
                    }
                }

                println("  7. Decompilation:        SUCCESS (" + decompDurationMs + " ms, " + lineCount + " lines C code)");
            } else {
                println("  7. Decompilation:        FAILED (" + decompDurationMs + " ms: " + results.getErrorMessage() + ")");
            }

            if (warnings.isEmpty()) {
                println("     - Compiler Warnings:  NONE");
            } else {
                println("     - Compiler Warnings:  " + warnings.size() + " warning(s)");
                for (String w : warnings) {
                    println("       * " + w);
                }
            }
        }

        // Properly dispose decompiler
        decompiler.dispose();

        println("\n================================================================================");
        println("ANALYSIS EXECUTION SUMMARY (PHASE 1.4.1):");
        println("  Total Target Routines:            " + totalTargets);
        println("  Successfully Disassembled:        " + totalDisasmSuccess + " / " + totalTargets +
                String.format(" (%.1f%%)", (totalDisasmSuccess * 100.0 / totalTargets)));
        println("  Function Model Created:           " + totalFuncSuccess + " / " + totalTargets +
                String.format(" (%.1f%%)", (totalFuncSuccess * 100.0 / totalTargets)));
        println("  ObjC Metadata Verified:           " + totalMetaVerified + " / " + totalTargets +
                String.format(" (%.1f%%)", (totalMetaVerified * 100.0 / totalTargets)));
        println("  Decompilation Succeeded:          " + totalDecompSuccess + " / " + totalTargets +
                String.format(" (%.1f%%)", (totalDecompSuccess * 100.0 / totalTargets)));
        println("  Objective-C Metadata Index Time:  " + indexElapsedMs + " ms");
        println("  Total Disassembly Time:           " + totalDisasmDurationMs + " ms");
        println("  Total Decompilation Time:         " + totalDecompDurationMs + " ms");
        println("  Total Duration:                   " + (indexElapsedMs + totalDisasmDurationMs + totalDecompDurationMs) + " ms");
        println("================================================================================");
    }
}
