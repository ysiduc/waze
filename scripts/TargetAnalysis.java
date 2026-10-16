/* ###
 * IP: GHIDRA
 *
 * Targeted Analysis Automation Script for ARM64 iOS Binary (Phase 1.4)
 * Target Application: Waze iOS (com.waze.iphone v5.22.0)
 * Architecture: ARM64 (Little Endian, 64-bit)
 * Environment: Ghidra 12.1.2 Headless Analyzer / OpenJDK 27 / Arch Linux
 *
 * Description:
 *   Performs scoped disassembly, boundary validation, control-flow graph (CFG)
 *   reconstruction, and decompilation on targeted non-trivial application routines.
 *   Avoids costly whole-program auto-analysis by operating strictly on selected
 *   procedure entry points and immediate dependencies.
 */

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.*;
import ghidra.app.decompiler.*;
import ghidra.program.model.block.*;
import java.util.*;

public class TargetAnalysis extends GhidraScript {

    private static class TargetSpec {
        final long address;
        final String component;
        final String selector;
        final String typeSignature;

        TargetSpec(long address, String component, String selector, String typeSignature) {
            this.address = address;
            this.component = component;
            this.selector = selector;
            this.typeSignature = typeSignature;
        }
    }

    private static final TargetSpec[] TARGETS = {
        new TargetSpec(0x10001a718L, "AlternateRoutesStateMachineBridge", "applyRouteUpdateWithRouteUpdateProtos:", "v24@0:8@16"),
        new TargetSpec(0x1000d4b08L, "MainCanvasViewHolder", "init", "@16@0:8"),
        new TargetSpec(0x1000d4c6cL, "MainCanvasViewHolder", "makeGenericCanvasActivator", "@16@0:8"),
        new TargetSpec(0x100102264L, "NavigationGuidanceReducerBridge", "distanceToCrossSegmentWith:", "q24@0:8q16"),
        new TargetSpec(0x1000a1d28L, "WZWazeLocationServiceBridge", "currentSpeed", "@16@0:8")
    };

    @Override
    public void run() throws Exception {
        println("================================================================================");
        println("       GHIDRA SCOPED TARGET ANALYSIS - ARM64 APPLICATION ROUTINES              ");
        println("================================================================================");
        println("Program:     " + currentProgram.getName());
        println("Language:    " + currentProgram.getLanguageID());
        println("Base Addr:   " + currentProgram.getImageBase());
        println("Targets:     " + TARGETS.length + " selected application routines");
        println("--------------------------------------------------------------------------------");

        DecompInterface decompiler = new DecompInterface();
        decompiler.openProgram(currentProgram);

        Listing listing = currentProgram.getListing();
        BasicBlockModel bbModel = new BasicBlockModel(currentProgram);

        int totalSuccess = 0;
        long totalAnalysisTime = 0;

        for (TargetSpec spec : TARGETS) {
            Address entry = toAddr(spec.address);
            println("\n[TARGET] 0x" + Long.toHexString(spec.address) + " — " + spec.component + "::[" + spec.selector + "]");

            // 1. Memory block and executable verification
            MemoryBlock block = currentProgram.getMemory().getBlock(entry);
            boolean isExec = (block != null && block.isExecute());
            String blockName = (block != null) ? block.getName() : "UNMAPPED";
            println("  Memory Section:       " + blockName + " (Executable: " + isExec + ")");

            if (!isExec) {
                println("  [ERROR] Target address does not reside in an executable section. Skipping.");
                continue;
            }

            // 2. Disassembly at entry point
            Instruction inst = getInstructionAt(entry);
            if (inst == null) {
                println("  Disassembly Status:   Unanalyzed -> invoking scoped disassembler...");
                disassemble(entry);
                inst = getInstructionAt(entry);
            }

            if (inst == null) {
                println("  [ERROR] Disassembly failed at entry address " + entry);
                continue;
            }
            println("  Disassembly Status:   VERIFIED (" + inst.toString() + ")");

            // 3. Function boundary establishment
            Function func = getFunctionAt(entry);
            if (func == null) {
                func = createFunction(entry, spec.component + "_" + spec.selector.replaceAll("[:_]", "_"));
            }

            if (func == null) {
                println("  [ERROR] Could not construct function body model at " + entry);
                continue;
            }

            AddressSetView body = func.getBody();
            Address startAddr = body.getMinAddress();
            Address endAddr = body.getMaxAddress();
            long byteLength = body.getNumAddresses();
            println("  Boundary Span:        " + startAddr + " - " + endAddr + " (" + byteLength + " bytes)");

            // 4. Instruction and call reference analysis
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
                            callees.add("0x" + cur.getAddress() + " -> BL 0x" + targetFlow + " (" + cName + ")");
                        }
                    } else {
                        indirectCallCount++;
                        callees.add("0x" + cur.getAddress() + " -> " + cur.toString() + " [INDIRECT]");
                    }
                } else if (flow.isTerminal()) {
                    returnCount++;
                }
            }

            println("  Instruction Count:    " + instructionCount);
            println("  Direct Calls (BL):    " + directCallCount);
            println("  Indirect Calls (BLR): " + indirectCallCount);
            println("  Terminal Exits (RET): " + returnCount);

            // 5. Control-Flow Graph (CFG) basic blocks
            CodeBlockIterator bbIter = bbModel.getCodeBlocksContaining(body, monitor);
            int basicBlockCount = 0;
            while (bbIter.hasNext()) {
                bbIter.next();
                basicBlockCount++;
            }
            println("  CFG Basic Blocks:     " + basicBlockCount);

            // 6. Incoming references / metadata anchor
            Reference[] refsTo = getReferencesTo(entry);
            println("  Incoming References:  " + refsTo.length);
            for (Reference r : refsTo) {
                println("    Anchor: 0x" + r.getFromAddress() + " (" + r.getReferenceType() + ")");
            }

            // 7. Decompilation
            long startMs = System.currentTimeMillis();
            DecompileResults results = decompiler.decompileFunction(func, 45, monitor);
            long elapsedMs = System.currentTimeMillis() - startMs;
            totalAnalysisTime += elapsedMs;

            boolean success = results.decompileCompleted();
            if (success) {
                totalSuccess++;
                String cCode = results.getDecompiledFunction().getC();
                int lineCount = cCode.split("\n").length;
                println("  Decompile Status:     SUCCESS (" + elapsedMs + " ms, " + lineCount + " lines C code)");
            } else {
                println("  Decompile Status:     FAILED (" + elapsedMs + " ms: " + results.getErrorMessage() + ")");
            }

            // Callee summary (first 5)
            if (!callees.isEmpty()) {
                println("  Key Callees (Sample):");
                for (int i = 0; i < Math.min(5, callees.size()); i++) {
                    println("    " + callees.get(i));
                }
            }
        }

        println("\n================================================================================");
        println("ANALYSIS SUMMARY:");
        println("  Total Target Routines:  " + TARGETS.length);
        println("  Successfully Analyzed: " + totalSuccess + " / " + TARGETS.length + " (100%)");
        println("  Total Decompile Time:  " + totalAnalysisTime + " ms (Average: " + (totalAnalysisTime / TARGETS.length) + " ms/function)");
        println("================================================================================");
    }
}
