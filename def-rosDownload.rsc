# =============================================================================
# RouterOS Download Function: Stage Specific Version (Main + Enabled Extras)
# -----------------------------------------------------------------------------
# Author: Sean Crites
# Created: 2025-12-13
# Updated: 2025-12-23
# Version: 2.9
# Dependencies: Outbound HTTPS access to download.mikrotik.com (port 443)
#               RouterOS >= v7.14.3
# Usage:
#
#  - Add Script:
#    /tool fetch url="https://raw.githubusercontent.com/seancrites/def-rosDownload/refs/heads/master/def-rosDownload.rsc" mode=https dst-path="def-rosDownload.rsc" output=file
#  - Load script:
#    /system script add name=def-rosDownload source=[:file get def-rosDownload.rsc contents]
#  - Run script:
#    /system script run def-rosDownload
#  - Verify script:
#    /system script environment print where name=rosDownload
#  - Make script persistent:
#    /system scheduler add name="load-rosDownload" interval=0 on-event="/system script run def-rosDownload" start-time=startup
#  - Use script as a function:
#    $rosDownload 7.19.4
#    $rosDownload 7.20.1
#    $rosDownload 6.49.10   (for supported downgrade paths)
#
# Description:
#
#   Defines global function 'rosDownload' to stage a specific RouterOS version.
#   Downloads main RouterOS package + all currently enabled extra packages
#   (e.g., ups, lora, etc) individually as local .npk files.
#
# https://github.com/seancrites/def-rosDownload
# =============================================================================

:global rosDownload do={
   # Validate required positional argument (target version)
   :if ([:len $1] = 0) do={
      :put "Error: Target version required."
      :put "Usage examples:"
      :put "   $rosDownload 7.19.4"
      :put "   $rosDownload 7.20.1"
      :put "   $rosDownload 6.49.10"
      :log error "rosDownload: Missing target version argument"
      :return false
   }

   :local targetVer $1
   :local arch [/system resource get architecture-name]
   :local currentVer [/system package update get installed-version]

   :put "rosDownload: Staging version $targetVer (Current: $currentVer)"
   :put "rosDownload: Architecture: $arch"
   :log info "rosDownload: Target $targetVer | Arch $arch | Current $currentVer"

   # Remove old .npk files to conserve flash space
   :foreach f in=[/file find type=".npk"] do={
      :local oldName [/file get [$f] name]
      :log info "rosDownload: Removing old package: $oldName"
      /file remove [$f]
   }

   # Download main routeros package (critical)
   :local mainFile "routeros-$targetVer-$arch.npk"
   :local mainUrl "https://download.mikrotik.com/routeros/$targetVer/$mainFile"

   :put "rosDownload: Downloading main: $mainUrl"
   :log info "rosDownload: Fetch main $mainUrl"
   /tool fetch url=$mainUrl mode=https dst-path=$mainFile output=file

   # Numeric iteration over enabled packages
   :local totalPkgs [:len [/system package find where disabled=no]]
   :local extraSuccessCount 0
   :local extraCount 0

   :for i from=0 to=($totalPkgs - 1) do={
      :local pkgName [/system package get number=$i name]
      :if ($pkgName != "routeros" && $pkgName != "system") do={
         :set extraCount ($extraCount + 1)
         :put "rosDownload: Found extra package: $pkgName (index $i)"
         :local extraFile "$pkgName-$targetVer-$arch.npk"
         :local extraUrl "https://download.mikrotik.com/routeros/$targetVer/$extraFile"

         :put "rosDownload: Attempting download for '$pkgName': $extraUrl"
         :log info "rosDownload: Fetch extra $pkgName $extraUrl"
         /tool fetch url=$extraUrl mode=https dst-path=$extraFile output=file

         :if ([:len [/file find name=$extraFile]] > 0) do={
            :set extraSuccessCount ($extraSuccessCount + 1)
            :put "rosDownload: Extra '$pkgName' staged successfully."
         } else={
            :log warning "rosDownload: Failed to download extra '$pkgName' (check URL/arch/version availability)"
            :put "Warning: Failed to download extra '$pkgName' (manual upload may be required)"
         }
      }
   }

   # Final status with contextual next-steps
   :if ([:len [/file find name=$mainFile]] > 0) do={
      :put "rosDownload: Main package staged successfully."
      :log info "rosDownload: Main staged"
      :if ($extraCount > 0) do={
         :put "rosDownload: $extraSuccessCount/$extraCount extras staged."
         :if ($extraSuccessCount = $extraCount) do={
            :log info "rosDownload: All extras ready"
         } else={
            :log warning "rosDownload: Partial extras failure"
         }
      } else={
         :put "rosDownload: No extra packages detected."
      }

      # String comparison for upgrade/downgrade detection
      :if ($targetVer > $currentVer) do={
         :put "rosDownload: This is an UPGRADE."
         :put "rosDownload: Apply with: /system reboot"
      } else={
         :if ($targetVer < $currentVer) do={
            :put "rosDownload: This is a DOWNGRADE."
            :put "rosDownload: Apply with: /system package downgrade  (confirm prompt, then auto-reboot)"
            :put "rosDownload: Note: Cannot downgrade below factory-software version (check /system resource print)"
         } else={
            :put "rosDownload: Target matches current version - no action needed."
         }
      }
   } else={
      :put "rosDownload: Main package failed. Check version/arch/internet."
      :log error "rosDownload: Main package download failed"
   }
}
