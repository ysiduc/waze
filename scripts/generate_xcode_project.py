#!/usr/bin/env python3
"""
Generates a complete, valid native Xcode project (project.pbxproj and scheme)
for WazeRecovery targeting iOS 16.0+.
"""

import os, sys, hashlib

def make_id(key):
    return hashlib.md5(key.encode('utf-8')).hexdigest()[:24].upper()

def main():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "WazeRecovery"))
    proj_dir = os.path.join(base_dir, "WazeRecovery.xcodeproj")
    scheme_dir = os.path.join(proj_dir, "xcshareddata", "xcschemes")
    os.makedirs(scheme_dir, exist_ok=True)

    # Collect source files
    source_files = []
    header_files = []
    resource_files = []

    for root, dirs, files in os.walk(base_dir):
        if "WazeRecovery.xcodeproj" in root or "build" in root or ".build" in root:
            continue
        for f in files:
            rel = os.path.relpath(os.path.join(root, f), base_dir)
            if f.endswith('.swift') or f.endswith('.cpp') or f.endswith('.mm') or f.endswith('.metal'):
                if not rel.startswith("Tests/"):
                    source_files.append(rel)
            elif f.endswith('.hpp') or f.endswith('.h'):
                header_files.append(rel)
            elif f == "Info.plist":
                resource_files.append(rel)

    source_files.sort()
    header_files.sort()
    resource_files.sort()

    print(f"Found {len(source_files)} source files, {len(header_files)} headers, {len(resource_files)} resources.")

    # PBX Objects
    pbx_file_refs = []
    pbx_build_files = []
    pbx_sources_build_phase = []

    group_children = []

    for s in source_files:
        file_id = make_id("FILE_" + s)
        build_id = make_id("BUILD_" + s)
        fname = os.path.basename(s)
        ftype = "sourcecode"
        if s.endswith('.swift'):
            ftype = "sourcecode.swift"
        elif s.endswith('.cpp'):
            ftype = "sourcecode.cpp.cpp"
        elif s.endswith('.mm'):
            ftype = "sourcecode.cpp.objcpp"
        elif s.endswith('.metal'):
            ftype = "sourcecode.metal"
        pbx_file_refs.append(f'\t\t{file_id} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = "{s}"; sourceTree = "<group>"; }};')
        pbx_build_files.append(f'\t\t{build_id} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {fname} */; }};')
        pbx_sources_build_phase.append(f'\t\t\t\t{build_id} /* {fname} in Sources */,')
        group_children.append(f'\t\t\t\t{file_id} /* {fname} */,')

    for h in header_files:
        file_id = make_id("FILE_" + h)
        fname = os.path.basename(h)
        pbx_file_refs.append(f'\t\t{file_id} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.h; path = "{h}"; sourceTree = "<group>"; }};')
        group_children.append(f'\t\t\t\t{file_id} /* {fname} */,')

    for r in resource_files:
        file_id = make_id("FILE_" + r)
        fname = os.path.basename(r)
        pbx_file_refs.append(f'\t\t{file_id} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "{r}"; sourceTree = "<group>"; }};')
        group_children.append(f'\t\t\t\t{file_id} /* {fname} */,')

    proj_id = make_id("PROJ_ROOT")
    main_group_id = make_id("MAIN_GROUP")
    target_id = make_id("TARGET_WAZE_RECOVERY")
    app_product_id = make_id("PRODUCT_WAZE_RECOVERY")
    sources_phase_id = make_id("PHASE_SOURCES")
    frameworks_phase_id = make_id("PHASE_FRAMEWORKS")
    resources_phase_id = make_id("PHASE_RESOURCES")
    config_debug_id = make_id("CONFIG_DEBUG")
    config_release_id = make_id("CONFIG_RELEASE")
    config_list_target_id = make_id("CONFIG_LIST_TARGET")
    config_list_proj_id = make_id("CONFIG_LIST_PROJ")

    pbx_file_refs.append(f'\t\t{app_product_id} /* WazeRecovery.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = WazeRecovery.app; sourceTree = BUILT_PRODUCTS_DIR; }};')

    pbx_content = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{chr(10).join(pbx_build_files)}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{chr(10).join(pbx_file_refs)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{frameworks_phase_id} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{main_group_id} = {{
			isa = PBXGroup;
			children = (
{chr(10).join(group_children)}
				{app_product_id} /* WazeRecovery.app */,
			);
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target_id} /* WazeRecovery */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {config_list_target_id} /* Build configuration list for PBXNativeTarget "WazeRecovery" */;
			buildPhases = (
				{sources_phase_id} /* Sources */,
				{frameworks_phase_id} /* Frameworks */,
				{resources_phase_id} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = WazeRecovery;
			productName = WazeRecovery;
			productReference = {app_product_id} /* WazeRecovery.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{proj_id} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					{target_id} = {{
						CreatedOnToolsVersion = 15.0;
					}};
				}};
			}};
			buildConfigurationList = {config_list_proj_id} /* Build configuration list for PBXProject "WazeRecovery" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {main_group_id};
			productRefGroup = {main_group_id};
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target_id} /* WazeRecovery */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{resources_phase_id} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{sources_phase_id} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{chr(10).join(pbx_sources_build_phase)}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{config_debug_id} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "c++17";
				CLANG_CXX_LIBRARY = "libc++";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_BITCODE = NO;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				HEADER_SEARCH_PATHS = (
					"$(inherited)",
					"NativeEngine",
				);
				INFOPLIST_FILE = "Resources/Info.plist";
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 5.22.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.waze.recovery";
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OBJC_BRIDGING_HEADER = "Resources/WazeRecovery-Bridging-Header.h";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		{config_release_id} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "c++17";
				CLANG_CXX_LIBRARY = "libc++";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_BITCODE = NO;
				HEADER_SEARCH_PATHS = (
					"$(inherited)",
					"NativeEngine",
				);
				INFOPLIST_FILE = "Resources/Info.plist";
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 5.22.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.waze.recovery";
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SWIFT_OBJC_BRIDGING_HEADER = "Resources/WazeRecovery-Bridging-Header.h";
				SWIFT_OPTIMIZATION_LEVEL = "-Owholemodule";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{config_list_proj_id} /* Build configuration list for PBXProject "WazeRecovery" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{config_debug_id} /* Debug */,
				{config_release_id} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{config_list_target_id} /* Build configuration list for PBXNativeTarget "WazeRecovery" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{config_debug_id} /* Debug */,
				{config_release_id} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */

	}};
	rootObject = {proj_id} /* Project object */;
}}
"""

    pbx_path = os.path.join(proj_dir, "project.pbxproj")
    with open(pbx_path, "w", encoding="utf-8") as f:
        f.write(pbx_content)
    print(f"Wrote PBX project to: {pbx_path}")

    # Write Scheme
    scheme_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_id}"
               BuildableName = "WazeRecovery.app"
               BlueprintName = "WazeRecovery"
               ReferencedContainer = "container:WazeRecovery.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "WazeRecovery.app"
            BlueprintName = "WazeRecovery"
            ReferencedContainer = "container:WazeRecovery.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "WazeRecovery.app"
            BlueprintName = "WazeRecovery"
            ReferencedContainer = "container:WazeRecovery.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    scheme_path = os.path.join(scheme_dir, "WazeRecovery.xcscheme")
    with open(scheme_path, "w", encoding="utf-8") as f:
        f.write(scheme_content)
    print(f"Wrote Scheme to: {scheme_path}")

if __name__ == "__main__":
    main()
