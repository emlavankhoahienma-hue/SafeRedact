import os
import hashlib

def generate_id(seed: str) -> str:
    h = hashlib.md5(seed.encode("utf-8")).hexdigest().upper()
    return h[:24]

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.join(base_dir, "SafeRedact.xcodeproj")
    os.makedirs(project_dir, exist_ok=True)
    
    swift_files = [
        ("App/SafeRedactApp.swift", "SafeRedactApp.swift"),
        ("Theme/AppTheme.swift", "AppTheme.swift"),
        ("Theme/VectorIconLibrary.swift", "VectorIconLibrary.swift"),
        ("Models/RedactModels.swift", "RedactModels.swift"),
        ("Engines/PIIDetectionEngine.swift", "PIIDetectionEngine.swift"),
        ("Engines/ImageRedactionEngine.swift", "ImageRedactionEngine.swift"),
        ("Engines/MetadataScrubberEngine.swift", "MetadataScrubberEngine.swift"),
        ("Engines/LibraryPrivacyScannerEngine.swift", "LibraryPrivacyScannerEngine.swift"),
        ("Services/LocalizationManager.swift", "LocalizationManager.swift"),
        ("ViewModels/RedactWorkspaceViewModel.swift", "RedactWorkspaceViewModel.swift"),
        ("Views/MainTabView.swift", "MainTabView.swift"),
        ("Views/SmartRedactView.swift", "SmartRedactView.swift"),
        ("Views/MetadataScrubberView.swift", "MetadataScrubberView.swift"),
        ("Views/WatermarkStudioView.swift", "WatermarkStudioView.swift"),
        ("Views/SettingsView.swift", "SettingsView.swift"),
    ]
    
    file_refs = {}
    build_files = {}
    
    for rel_path, filename in swift_files:
        f_id = generate_id(f"fileref_{rel_path}")
        b_id = generate_id(f"buildfile_{rel_path}")
        file_refs[rel_path] = (f_id, filename)
        build_files[rel_path] = b_id
        
    info_plist_id = generate_id("fileref_Info.plist")
    
    product_file_id = generate_id("product_app")
    target_id = generate_id("native_target")
    project_root_id = generate_id("project_root")
    main_group_id = generate_id("main_group")
    products_group_id = generate_id("products_group")
    sources_build_phase_id = generate_id("sources_build_phase")
    resources_build_phase_id = generate_id("resources_build_phase")
    frameworks_build_phase_id = generate_id("frameworks_build_phase")
    
    config_debug_target = generate_id("config_debug_target")
    config_release_target = generate_id("config_release_target")
    config_list_target = generate_id("config_list_target")
    
    config_debug_proj = generate_id("config_debug_proj")
    config_release_proj = generate_id("config_release_proj")
    config_list_proj = generate_id("config_list_proj")

    pbx = []
    pbx.append("// !$*UTF8*$!")
    pbx.append("{")
    pbx.append("\tarchiveVersion = 1;")
    pbx.append("\tclasses = {")
    pbx.append("\t};")
    pbx.append("\tobjectVersion = 54;")
    pbx.append("\tobjects = {")
    
    # PBXBuildFile
    pbx.append("\n/* Begin PBXBuildFile section */")
    for rel_path, _ in swift_files:
        b_id = build_files[rel_path]
        f_id, fname = file_refs[rel_path]
        pbx.append(f"\t\t{b_id} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {f_id} /* {fname} */; }};")
    pbx.append("/* End PBXBuildFile section */")

    # PBXFileReference
    pbx.append("\n/* Begin PBXFileReference section */")
    pbx.append(f"\t\t{product_file_id} /* SafeRedact.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = SafeRedact.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    pbx.append(f"\t\t{info_plist_id} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};")
    for rel_path, fname in swift_files:
        f_id, _ = file_refs[rel_path]
        pbx.append(f"\t\t{f_id} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{rel_path}\"; sourceTree = \"<group>\"; }};")
    pbx.append("/* End PBXFileReference section */")

    # PBXFrameworksBuildPhase
    pbx.append("\n/* Begin PBXFrameworksBuildPhase section */")
    pbx.append(f"\t\t{frameworks_build_phase_id} /* Frameworks */ = {{")
    pbx.append("\t\t\tisa = PBXFrameworksBuildPhase;")
    pbx.append("\t\t\tbuildActionMask = 2147483647;")
    pbx.append("\t\t\tfiles = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pbx.append("\t\t};")
    pbx.append("/* End PBXFrameworksBuildPhase section */")

    # PBXGroup
    pbx.append("\n/* Begin PBXGroup section */")
    pbx.append(f"\t\t{main_group_id} = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    pbx.append(f"\t\t\t\t{info_plist_id} /* Info.plist */,")
    for rel_path, _ in swift_files:
        f_id, fname = file_refs[rel_path]
        pbx.append(f"\t\t\t\t{f_id} /* {fname} */,")
    pbx.append(f"\t\t\t\t{products_group_id} /* Products */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")
    
    pbx.append(f"\t\t{products_group_id} /* Products */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    pbx.append(f"\t\t\t\t{product_file_id} /* SafeRedact.app */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tname = Products;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")
    pbx.append("/* End PBXGroup section */")

    # PBXNativeTarget
    pbx.append("\n/* Begin PBXNativeTarget section */")
    pbx.append(f"\t\t{target_id} /* SafeRedact */ = {{")
    pbx.append("\t\t\tisa = PBXNativeTarget;")
    pbx.append(f"\t\t\tbuildConfigurationList = {config_list_target} /* Build configuration list for PBXNativeTarget \"SafeRedact\" */;")
    pbx.append("\t\t\tbuildPhases = (")
    pbx.append(f"\t\t\t\t{sources_build_phase_id} /* Sources */,")
    pbx.append(f"\t\t\t\t{frameworks_build_phase_id} /* Frameworks */,")
    pbx.append(f"\t\t\t\t{resources_build_phase_id} /* Resources */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tbuildRules = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdependencies = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tname = SafeRedact;")
    pbx.append("\t\t\tproductName = SafeRedact;")
    pbx.append(f"\t\t\tproductReference = {product_file_id} /* SafeRedact.app */;")
    pbx.append("\t\t\tproductType = \"com.apple.product-type.application\";")
    pbx.append("\t\t};")
    pbx.append("/* End PBXNativeTarget section */")

    # PBXProject
    pbx.append("\n/* Begin PBXProject section */")
    pbx.append(f"\t\t{project_root_id} /* Project object */ = {{")
    pbx.append("\t\t\tisa = PBXProject;")
    pbx.append("\t\t\tattributes = {")
    pbx.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    pbx.append("\t\t\t\tLastUpgradeCheck = 1500;")
    pbx.append("\t\t\t\tTargetAttributes = {")
    pbx.append(f"\t\t\t\t\t{target_id} = {{")
    pbx.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    pbx.append("\t\t\t\t\t};")
    pbx.append("\t\t\t\t};")
    pbx.append("\t\t\t};")
    pbx.append(f"\t\t\tbuildConfigurationList = {config_list_proj} /* Build configuration list for PBXProject \"SafeRedact\" */;")
    pbx.append("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    pbx.append("\t\t\tdevelopmentRegion = en;")
    pbx.append("\t\t\thasScannedForEncodings = 0;")
    pbx.append("\t\t\tknownRegions = (")
    pbx.append("\t\t\t\ten,")
    pbx.append("\t\t\t\tBase,")
    pbx.append("\t\t\t);")
    pbx.append(f"\t\t\tmainGroup = {main_group_id};")
    pbx.append(f"\t\t\tproductRefGroup = {products_group_id} /* Products */;")
    pbx.append("\t\t\tprojectDirPath = \"\";")
    pbx.append("\t\t\tprojectRoot = \"\";")
    pbx.append("\t\t\ttargets = (")
    pbx.append(f"\t\t\t\t{target_id} /* SafeRedact */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t};")
    pbx.append("/* End PBXProject section */")

    # PBXResourcesBuildPhase
    pbx.append("\n/* Begin PBXResourcesBuildPhase section */")
    pbx.append(f"\t\t{resources_build_phase_id} /* Resources */ = {{")
    pbx.append("\t\t\tisa = PBXResourcesBuildPhase;")
    pbx.append("\t\t\tbuildActionMask = 2147483647;")
    pbx.append("\t\t\tfiles = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pbx.append("\t\t};")
    pbx.append("/* End PBXResourcesBuildPhase section */")

    # PBXSourcesBuildPhase
    pbx.append("\n/* Begin PBXSourcesBuildPhase section */")
    pbx.append(f"\t\t{sources_build_phase_id} /* Sources */ = {{")
    pbx.append("\t\t\tisa = PBXSourcesBuildPhase;")
    pbx.append("\t\t\tbuildActionMask = 2147483647;")
    pbx.append("\t\t\tfiles = (")
    for rel_path, _ in swift_files:
        b_id = build_files[rel_path]
        _, fname = file_refs[rel_path]
        pbx.append(f"\t\t\t\t{b_id} /* {fname} in Sources */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pbx.append("\t\t};")
    pbx.append("/* End PBXSourcesBuildPhase section */")

    # XCBuildConfiguration
    pbx.append("\n/* Begin XCBuildConfiguration section */")
    pbx.append(f"\t\t{config_debug_proj} /* Debug */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    pbx.append("\t\t\t\tCLANG_ANALYZER_NONNULL = YES;")
    pbx.append("\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";")
    pbx.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    pbx.append("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
    pbx.append("\t\t\t\tCOPY_PHASE_STRIP = NO;")
    pbx.append("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
    pbx.append("\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;")
    pbx.append("\t\t\t\tENABLE_TESTABILITY = YES;")
    pbx.append("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
    pbx.append("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
    pbx.append("\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (")
    pbx.append("\t\t\t\t\t\"DEBUG=1\",")
    pbx.append("\t\t\t\t\t\"$(inherited)\",")
    pbx.append("\t\t\t\t);")
    pbx.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;")
    pbx.append("\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;")
    pbx.append("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
    pbx.append("\t\t\t\tSDKROOT = iphoneos;")
    pbx.append("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
    pbx.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Debug;")
    pbx.append("\t\t};")
    
    pbx.append(f"\t\t{config_release_proj} /* Release */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    pbx.append("\t\t\t\tCLANG_ANALYZER_NONNULL = YES;")
    pbx.append("\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";")
    pbx.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    pbx.append("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
    pbx.append("\t\t\t\tCOPY_PHASE_STRIP = NO;")
    pbx.append("\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";")
    pbx.append("\t\t\t\tENABLE_NS_ASSERTIONS = NO;")
    pbx.append("\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;")
    pbx.append("\t\t\t\tGCC_OPTIMIZATION_LEVEL = s;")
    pbx.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;")
    pbx.append("\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;")
    pbx.append("\t\t\t\tSDKROOT = iphoneos;")
    pbx.append("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
    pbx.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";")
    pbx.append("\t\t\t\tVALIDATE_PRODUCT = YES;")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Release;")
    pbx.append("\t\t};")
    
    pbx.append(f"\t\t{config_debug_target} /* Debug */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = \"\";")
    pbx.append("\t\t\t\tCODE_SIGN_STYLE = Manual;")
    pbx.append("\t\t\t\tCODE_SIGNING_ALLOWED = NO;")
    pbx.append("\t\t\t\tCODE_SIGNING_REQUIRED = NO;")
    pbx.append("\t\t\t\tCODE_SIGN_IDENTITY = \"\";")
    pbx.append("\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
    pbx.append("\t\t\t\tINFOPLIST_FILE = Info.plist;")
    pbx.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;")
    pbx.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
    pbx.append("\t\t\t\t\t\"$(inherited)\",")
    pbx.append("\t\t\t\t\t\"@executable_path/Frameworks\",")
    pbx.append("\t\t\t\t);")
    pbx.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.ace4youblade.saferedact;")
    pbx.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    pbx.append("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;")
    pbx.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    pbx.append("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Debug;")
    pbx.append("\t\t};")
    
    pbx.append(f"\t\t{config_release_target} /* Release */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = \"\";")
    pbx.append("\t\t\t\tCODE_SIGN_STYLE = Manual;")
    pbx.append("\t\t\t\tCODE_SIGNING_ALLOWED = NO;")
    pbx.append("\t\t\t\tCODE_SIGNING_REQUIRED = NO;")
    pbx.append("\t\t\t\tCODE_SIGN_IDENTITY = \"\";")
    pbx.append("\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
    pbx.append("\t\t\t\tINFOPLIST_FILE = Info.plist;")
    pbx.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;")
    pbx.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
    pbx.append("\t\t\t\t\t\"$(inherited)\",")
    pbx.append("\t\t\t\t\t\"@executable_path/Frameworks\",")
    pbx.append("\t\t\t\t);")
    pbx.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.ace4youblade.saferedact;")
    pbx.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    pbx.append("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;")
    pbx.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    pbx.append("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Release;")
    pbx.append("\t\t};")
    pbx.append("/* End XCBuildConfiguration section */")

    # XCConfigurationList
    pbx.append("\n/* Begin XCConfigurationList section */")
    pbx.append(f"\t\t{config_list_proj} /* Build configuration list for PBXProject \"SafeRedact\" */ = {{")
    pbx.append("\t\t\tisa = XCConfigurationList;")
    pbx.append("\t\t\tbuildConfigurations = (")
    pbx.append(f"\t\t\t\t{config_debug_proj} /* Debug */,")
    pbx.append(f"\t\t\t\t{config_release_proj} /* Release */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    pbx.append("\t\t\tdefaultConfigurationName = Release;")
    pbx.append("\t\t};")
    
    pbx.append(f"\t\t{config_list_target} /* Build configuration list for PBXNativeTarget \"SafeRedact\" */ = {{")
    pbx.append("\t\t\tisa = XCConfigurationList;")
    pbx.append("\t\t\tbuildConfigurations = (")
    pbx.append(f"\t\t\t\t{config_debug_target} /* Debug */,")
    pbx.append(f"\t\t\t\t{config_release_target} /* Release */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    pbx.append("\t\t\tdefaultConfigurationName = Release;")
    pbx.append("\t\t};")
    pbx.append("/* End XCConfigurationList section */")

    pbx.append("\t};")
    pbx.append(f"\trootObject = {project_root_id} /* Project object */;")
    pbx.append("}")
    
    pbxproj_path = os.path.join(project_dir, "project.pbxproj")
    with open(pbxproj_path, "w", encoding="utf-8") as f:
        f.write("\n".join(pbx) + "\n")
    print(f"Generated {pbxproj_path}")
    
    # Also generate SafeRedact.xcscheme
    schemes_dir = os.path.join(project_dir, "xcshareddata", "xcschemes")
    os.makedirs(schemes_dir, exist_ok=True)
    scheme_path = os.path.join(schemes_dir, "SafeRedact.xcscheme")
    
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
               BuildableName = "SafeRedact.app"
               BlueprintName = "SafeRedact"
               ReferencedContainer = "container:SafeRedact.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <LaunchAction
      buildConfiguration = "Release"
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
            BuildableName = "SafeRedact.app"
            BlueprintName = "SafeRedact"
            ReferencedContainer = "container:SafeRedact.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
</Scheme>
"""
    with open(scheme_path, "w", encoding="utf-8") as f:
        f.write(scheme_content.strip() + "\n")
    print(f"Generated {scheme_path}")

if __name__ == "__main__":
    main()
