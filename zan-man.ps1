# File Created April 23, 2020 (give or take one day)
##
### Zandronum Cluster Configuration Manager (Zan-Man) PowerShell Edition
##
# NOTE: This will require Powershell v3.0 or later to run properly on your machine!
#
# Regretfully, I opted not to use a class structure/hierarchy.  I want to move this to Python,
#   where I can do that on a high-level programming language.  Can't be sure, but I think classes
#   would make this more like a .NET script and I don't know if that's really good design, since
#   this is basically meant to just be a big batch file in spirit, haha.
#
#   This wil be so much more awesome in Python!
##
###

$script =
{
    function Replace-CMDPATH
    {
        # This function basically parses %PATH%, but it can also have server name be the leading folder.
        #   I actually don't know why this even needs to be a function.  Why does it have to perform the fliparoo?
        Param ( [String] $cmd, [String] $start, [Boolean] $bwd )
        if ($cmd -Match ".*%PATH%.*") {
            $folder_switch_1 = Split-Path $PSScriptRoot -NoQualifier
            $folder_switch_1 = $folder_switch_1 -replace "\\", "-"
            $folder_switch_1 = $folder_switch_1.Substring(1, ($folder_switch_1.Length - 1))
            $part_1 = $PSScriptRoot + "\TMP-Confs\"
            $start_trunc = $start.Substring($PSScriptRoot.Length)
            $folder_switch_2 =  $start_trunc -Replace "^\\([^\\]+\\)(.+)$", '$1'
            $part_2 = $start_trunc -Replace "^\\([^\\]+\\)(.+)$", '$2'
            if ($bwd) {
                $cmd = $cmd -Replace "%PATH%", ($part_1 + $folder_switch_2 + $folder_switch_1 + "\" + $part_2)
                # Suggestion, maybe remove folder switch 1 because it's pointless here in terms of the sandbox working or not.
            } else {
                $cmd = $cmd -Replace "%PATH%", ($part_1 + $folder_switch_1 + "\" + $folder_switch_2 + $part_2)
            }
            $cmd = $cmd -Replace "\\", "/"
#           $cfg_path = Split-Path -NoQualifier $cfg_path
            return $cmd
        } else {
            # This is never (!) supposed to happen!
            ECHO "No custom path."
            return -1
        }
    }

    # Source of this function:
    #   https://stackoverflow.com/questions/13738236/how-can-i-force-a-powershell-script-to-wait-overwriting-a-file-until-another-pro
    function Test-FileLock
    {
        Param ( [String] $Path )
        $oFile = New-Object System.IO.FileInfo $Path    
        if ((Test-Path -Path $Path) -eq $false) {
            $false
            return
        }      
        Try {
            $oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
            if ($oStream) {
                $oStream.Close()
            }
                $false
        } Catch {
            # file is locked by a process.
            $true
        }
    }

    function Parse_ZanCFG
    {
        Param( [String[]] $start_a, [String] $server, [String[]] $fnames, [String] $zandir, [Boolean] $greedy, [Boolean] $revert, [String] $cmd = "", [String[]] $rev_files = @(""), [Int] $layer = 0, [Boolean] $grabbed_fullname = [Boolean]0, [String] $full_title = "",[Boolean] $stripped = [Boolean]0 )
        # Parses the Zandronum configuration file.  Function structure will differ depending on the value of $greedy.
        #
        # If $greedy is not true, then we will attempt to replace the original file with a file that has all of the information.
        #   That means, the user will have to call this function again to revert everything back.
        #
        # To accomplish this, the default value of $rev_files is @(""), which means that no reversion has happened yet.  So, we can remember
        #   to return to the user a string-array of all of the file names with their associated file paths.  Thus, the user will call
        #   the function again with this value.
        if ($layer -eq 0) {
            # Recursion begins.  Set layer to its correct number.
            $layer = 4
            if ($sub_ini) {
                # Subcluster .ini
            }
        }
        if ($layer -ne 4) {
            $old_rev_files = $rev_files
        }

        if (-not $greedy) {      
            if (-not $revert) {
                $i = [Int]0
                $len = $fnames.Count
                $len_check = $start_a.Count
                if ($len -ne $len_check) {
                    ECHO "Something's wrong with the array lengths of $start_a or $fnames!"
                    return -1
                }
                if ($layer -eq 4) {
                    ECHO "test"
                }
                While ($i -ne $len) {
                    $sandbox_loc = Split-Path $PSScriptRoot -NoQualifier
                    $sandbox_loc = $sandbox_loc -replace "\\", "-"
                    $sandbox_loc = $sandbox_loc.Substring(1, ($sandbox_loc.Length - 1))
                    # We can't have the following characters in filenames: \ / : * ? " < > |
                    $server_dir = $server -Replace '[\\/:*?"<>|]', ""
                    if ($stripped) {
                        $sandbox_loc = $PSScriptRoot + "\TMP-Confs\" + $server_dir + "\" + $sandbox_loc + "\"
                    } else {
                        $sandbox_loc = $PSScriptRoot + "\TMP-Confs\" + $server_dir + "\" + $sandbox_loc
                    }
                    # Okay, this is really, really horrible!  If $strp_start is equal to $PSScript without
                    #   the extra slash, we need to know.  But, we can't have the extra slash it from $start_a.
                    #   So, what to do?  Lot's of string manipulation!  :(
                    $strp_start = Split-Path -NoQualifier $start_a[$i]
                    if ($layer -eq 2) {
                        #$strp_start = $strp_start.Substring($PSScriptRoot.Length - 2)
                        #$strp_start = $strp_start[0..($strp_start.Length - 2)]
                        #$strp_start = -Join $strp_start
                        #$strp_start = $strp_start -Replace "\\", "/"
                        #
                        # If layer equals two, this should just equal "/", not "//" !
                        $strp_start = "/"
                    } else {
                        $strp_start = $strp_start.Substring($PSScriptRoot.Length - 1)
                    }
                    $sandbox_loc = $sandbox_loc -Replace "\\", "/"
                    if ($layer -ne 2) {
                        $new_dir = $sandbox_loc + "\" + $strp_start
                    } else {
                        $new_dir = $sandbox_loc + $strp_start
                    }
                    if ([boolean]0) { #if (-not $stripped) {
                        $strp_start = $strp_start.Substring(1)
                        #$stripped = [Boolean]1
                        $new_dir = $sandbox_loc + "\" + $strp_start
                    }
                    
                    if ($layer -ne 2) {
                        New-Item -ItemType Directory -Force -Path ($new_dir)
                    } else {
                        # Noticed a weird bug on this later with lots of slashes.
                        ECHO "Testing"
                    }
                    # I don't know if file-locking would really have an effect here, but it did before.  So, I'm instead electing to
                    #     "sandbox" each configuration.  Also, memory is conservative whereas file expenditure will be double as you can see.
                    #
                    # Halving the file space would require having the whole file contents in memory, as we can't have a read buffer stream
                    #     and also use a write buffer stream on the same file at the same time; it would have to happen one at a time, such that
                    #     line changes need to happen in memory.  Anyway, this method does one line at a time, which is the least consuming in
                    #     terms of memory usage.
                    #
                    # TODO: Add a different boolean Parameter to allow user to choose greedy file or not.  Different from greedy memory consumption
                    #         or basically what the boolean $greedy Paramater is technically for.
                    if (-not $stripped) {
                        if ($layer -ne 3) {
                            $next_cfg_path = $PSScriptRoot + "\" + $strp_start + $fnames[$i] # + "\"  + $fnames[$i]
                            $next_cfg_path = $next_cfg_path -Replace "/", "\"
                        } else {
                            $next_cfg_path = $PSScriptRoot + "\" + $fnames[$i]
                            $next_cfg_path = $next_cfg_path -Replace "/", "\"
                        }
                    }
                    if ($layer -ne 2) {
                        $next_cfg_path = $PSScriptRoot + "\" + $strp_start + $fnames[$i]
                    } else {
                        $next_cfg_path = $PSScriptRoot + "\" + $fnames[$i]
                    }
                    $next_cfg_path = $next_cfg_path -Replace "/", "\"
                    #$new_orig_fn = $PSScriptRoot + "\" + $strp_start + "orig-" + $fnames[$i]
                    #$new_orig_fn = $new_orig_fn -replace "/", "\"
                    if ($layer -ne 2) {
                        $new_orig_fn = $sandbox_loc + "\" + $strp_start + "orig-" + $fnames[$i]
                    } else {
                        $new_orig_fn = $sandbox_loc + "\orig-" + $fnames[$i]
                    }
                    $new_orig_fn = $new_orig_fn -replace "/", "\"
                    Copy-Item -Force $next_cfg_path ($new_orig_fn)
                    # Now go line by line
                    Get-Content ($new_orig_fn) -ReadCount 1 | ForEach-Object {
                        if ( (-not ($_ -Match "^//.*")) -and (-not ($_ -Match "^SV_MOTD.*")) ) {
                            # We can't have backslashes!
                            $line = $_ -Replace "%SERVER%", $server -Replace "%ZANDIR%", "$zandir"
                            $line = $line -Replace "\\", "/"
                        } else {
                            $line = $_ -Replace "%SERVER%", $server
                            if ($grabbed_fullname) {
                                $line = $line -Replace "%FULLSERVER%", "$zandir"
                                # No unnecessary backslashes in server name, please!  Put them in the MOTD.
                            }
                        }
                        if ($line -Match "exec .*") { # found a Match, or last layer
                            if ($layer -ne 1) {
                                $line = $_ -Replace "%SERVER%", $server -Replace "%ZANDIR%", "$zandir"
                                if ($layer -ne 2) {
                                    if ($layer -eq 4) {
                                        $cfg_typo = [Boolean]0
                                        # TODO: Make this whole outlying function work with layer 3, e.g. with Clusters enabled only
                                        $chk_loc = $start_a.Substring($PSScriptRoot.Length)
                                        $chk_loc = $chk_loc -Replace "^(.*\\).*\\$", '$1'
                                        $chk_loc = $chk_loc -Replace "\\", "/"
                                        # Remove exec "%ZANMANDIR% as well as remove /.*.cfg and remove ;" at the end
                                        #   (NOTE: This implies you shouldn't find %ZANDIR% here.)
                                        $chk_line = $line.Substring(17)
                                        $chk_line = $chk_line -Replace "^(.*/).*\.cfg.*$", '$1'
                                        $chk_line = $chk_line -Replace "\\", "/"
                                        try {
                                            # We are checking the number of slashes.  If it equals two, then it's presumably a custom cfg, one means not custom cfg. #TODO: make this more readable
                                            $chk_cust = $start_a.Substring(((($start_a[0].Substring($PSScriptRoot.Length).Length) - $chk_line.Length) - $start_a[0].Length) * [Int]-1)
                                        } catch [System.ArgumentOutOfRangeException] {
                                            ECHO "It would seem that there is a problem with the grabbed .cfg file from the script being in a shorter directory than what's in your .cfg file."
                                            ECHO "This could happen due to a couple missing characters in your 'exec' line.  Check for typos?"
                                            return -1
                                        }
                                        $chk_cust = ($chk_cust -Replace "\\", "/").Split("/").GetUpperBound(0)
                                        if (($chk_loc -ne $chk_line) -and (($chk_cust -gt 2) -or ($chk_cust -eq 0))) {
                                            $cfg_typo = [Boolean]1
                                        }
                                        if ($chk_cust -eq 1) {
                                            # TODO: Check that there's actually a custom config?
                                            ECHO "An extra slash was detected that does not belong to the subcluster directory.  It is probably a custom .cfg folder in your subcluster."
                                            ECHO "If it is not, make sure.  This is just one extra slash!  Any more than one extra slash will break the script."
                                        }
                                        $line = $line -Replace "%ZANMANDIR%", ($sandbox_loc)
                                        $line = $line -Replace "\\", "/"
                                        #$line = $line -Replace "%ZANMANDIR%",( $PSScriptRoot + "\TMP-Confs\" + $server + "\")
                                    } else {
                                        if ($layer -eq 3) {
                                            $strp_start = $strp_start[0..($strp_start.Length - 2)]
                                            $strp_start = -Join $strp_start
                                            $strp_start = $strp_start -Replace "\\", "/"
                                            $line = $line -Replace "%ZANMANDIR%", $sandbox_loc # Honestly, not sure why this happens
                                            $line = $line -Replace "\\", "/"
                                        } else {
                                        $line = $line -Replace "%ZANMANDIR%", ($sandbox_loc + $strp_start)
                                        $line = $line -Replace "\\", "/"
                                        }
                                    }
                                    if (-not $cfg_typo) {
                                        $new_cfg = $line -Replace "exec ", "" -Replace '"', "" -Replace ";", ""
                                        $repl = $sandbox_loc -Replace ("\\", "/")
                                        $new_cfg = $new_cfg.Replace($repl, $PSScriptRoot) -Replace "/", "\"
                                    } else {
                                        # Sorry, but can't be supported right now.
                                        ECHO "Sorry, but your subcluster or cluster file (the first one) has a typo in the file path!"
                                        ECHO "If you were trying to make it a different path than the one you're in, please don't do that!"
                                        ECHO "Also, make sure all your other config files Match with the format:"
                                        ECHO "%ZANMANDIR%/Clusters/Subcluster_Name/any_name.cfg"
                                        ECHO "or, %ZANMANDIR%/Clusters/any_name.cfg if you are not using subclusters right now!"
                                        ECHO "Remember, check ALL files!"
                                        return -1
                                    }
                                } else {
                                    $line = $line -Replace "%ZANMANDIR%", $sandbox_loc
                                    $line = $line -Replace "\\", "/"
                                    $new_cfg = $line -Replace "exec ", "" -Replace '"', "" -Replace ";", ""
                                    $repl = $sandbox_loc -Replace ("\\", "/")
                                    $new_cfg = $new_cfg.Replace($repl, $PSScriptRoot) -Replace "/", "\"
                                }
                            }
                            if ($layer -eq 4) {
                                $rev_files[0] = $new_cfg
                            } else {
                                if ($layer -ne 1) {
                                    # layer 1 will not have any new cfg files - they are the bottom layer.
                                    $rev_files += $new_cfg
                                }
                            }
                        } else {
                            $line = $line -Replace "%ZANMANDIR%", $PSScriptRoot
                            $line = $line -Replace "\\", "/"
                        }
                        if ($line -Match "^LogFile .*") { # parse the log file with %ZANMANDIR% since we couldn't do it earlier
                            if ($grabbed_fullname) {
                                $line = $_ -Replace "%ZANDIR%", "$zandir"
                                # Zandonum log filenames are currently limited to 512 characters including path and qualifier.
                                #    I do suspect it doesn't like certain characters, but I can't be certain.  Sometimes it didn't work.
                                #    Worst case, just add it as -LogFile to the command and what not.
                                $log_name = "(-) " + ($fnames[0] -Replace "\.cfg", "") + " (-) " + ($full_title -Replace "%LOGFILENAME%", "" -Replace "\\", "/")
#                               $log_name = ($fnames[$i] -Replace "\.cfg", "") + "_" + ($full_title -Replace "\\", "/")
#                               $log_name = ($fnames[$i] -Replace "\.cfg", "") + "_" + $server
                                $log_name = $log_name -Replace " ", "_" -Replace ":", "-"
                                $line = $line -Replace "%ZANMANDIR%", $PSScriptRoot -Replace "%SERVER%", $log_name
#                               $line = $line -Replace "\\", "/" -Replace "'", "_" -Replace "\(", "_" -Replace "\)", "_" #-Replace "-", "_"
                                # Source for this next line:
                                #   https://stackoverflow.com/questions/19917106/use-powershell-to-replace-subsection-of-regex-result
                                # (NOTE: single quotes on the last one is crucial for it to work)
#                               $line = $line -Replace "[^A-Za-z0-9]+(\.log.*$)", '$1'
#                               $line = $line -Replace "_+", " " -Replace "(.*[/])[^A-Za-z0-9](.*\.log.*$)", '$1$2'
                                $full_title = $full_title + $log_name # This has been giving me problems, so going to try to add -LogFile to $cmd.
                                # TODO: Detect if $full_title is declared at the first file or not.  If not, then it's an array, and we need
                                #         to grab the last element of that array as opposed to using $full_title. (Possibly.)
                            } else {
                                # It's just a matter of the user having their LogFile too close to the top, before SV_HostName.
                                ECHO "Suggest putting your LogFile command at the end of the script, before SV_HostName!"
                                # We can't have the following characters in filenames: \ / : * ? " < > |
                                $server_dir = $server -Replace '[\/:*?"<>|]', ""
                                $line = $line -Replace "%ZANMANDIR%", $PSScriptRoot -Replace "%SERVER%", $server_dir
                                $line = $line -Replace "\\", "/"
                            }
                        }
                        if ($line -Match "SV_HostName .*") {
                            $line = $_ -Replace "%SERVER%", $server -Replace "%ZANDIR%", "$zandir"
                            if (-not $grabbed_fullname) { # Only grab it once, since Global Config has its own backup one.
                                # Need the server hostname for our folder name, not the wad name.
                                $grabbed_fullname = [Boolean]1
                                $full_title = $line -Replace "^.*SV_HostName ", "" -Replace '"', "" -Replace ";", ("" + "%LOGFILENAME%")
                            }
                        }
                        if ($stripped) {
                            Add-Content -Force -Path ($sandbox_loc + $strp_start + $fnames[$i]) -Value $line
                        }
                        if (($layer -eq 4) -or (-not $stripped)) {
                            if ($layer -ne 3) {
                                # when layer equals two, that first "\" should not need to be there.
                                if ($layer -eq 2) {
                                    $new_file_loc = $sandbox_loc + $strp_start + $fnames[$i]
                                } else {
                                    $new_file_loc = $sandbox_loc + "\" + $strp_start + $fnames[$i]
                                }
                            } else {
                                $new_file_loc = $sandbox_loc + "\" + $strp_start + "\" + $fnames[$i]
                            }
                            $new_file_loc = $new_file_loc -Replace "/", "\"
                            Add-Content -Force -Path ($new_file_loc) -Value $line
                        }
#                       if ((-not $stripped) -and ($layer -ne 4)) {
#                           Add-Content -Force -Path ($sandbox_loc + $strp_start + "\" + $fnames[$i]) -Value $line
#                       }
                    }
                    $i = $i + 1
                }
                if ($layer -eq 1) {
                    if (-not $grabbed_fullname) {
                        # Forgot a server name?
                        ECHO "Even if you forgot a server name, Global Settings should have its own default SV_HostName setting just in case!"
                    }
                    Return $full_title
                    # $rev_files
                    # TODO: Figure out if reverting is really necessary anymore
                } else {
                    $layer = $layer - 1

                    if ($layer -ne 3) {
                        if ($old_rev_files.Count -ne [Int]1) {
                            $i = 0 # $i is already initialized as an [Int]
                            # Inspiration source for next line of code: https://stackoverflow.com/questions/47387016/array-subtraction-in-powershell
                            $new_cfg_a = $rev_files | Where-Object {$_ -notin $old_rev_files}
                            $len = $new_cfg_a.Count
                            $new_cfg_fnames = New-Object String[] $len
                            $new_cfg_paths = New-Object String[] $len
                            While ($i -ne $len) {
                                $new_cfg_fnames[$i] = Split-Path $new_cfg_a[$i] -Leaf
                                $fdir = $new_cfg_a[$i] -Split $new_cfg_fnames[$i]
                                $new_cfg_paths[$i] = $fdir[0]
                                $i = $i + 1
                            }
                        } else {
                            # Inspiration source for next line of code: https://stackoverflow.com/questions/18018892/pick-last-item-from-list-in-powershell
                            $new_cfg_a = $rev_files | Select-Object -Last 1
                            $new_cfg_fnames = @("")
                            $new_cfg_paths = @("")
                            $new_cfg_fnames[0] = Split-Path $new_cfg_a -Leaf
                            $fdir = $new_cfg_a -Split $new_cfg_fnames[0]
                            $new_cfg_paths[0] = $fdir[0]
                        }
                    } else {
                        $new_cfg_fnames = @("")
                        $new_cfg_paths = @("")
                        $new_cfg_a = $rev_files
                        $new_cfg_fnames[0] = Split-Path $new_cfg_a -Leaf
                        $fdir = $new_cfg_a -Split $new_cfg_fnames[0]
                        $new_cfg_paths[0] = $fdir[0]
                    }
                    Parse_ZanCFG $new_cfg_paths $server $new_cfg_fnames $zandir $greedy $revert $cmd $rev_files $layer $grabbed_fullname $full_title $stripped # we're not actually using $cmd, but it needs to be passed anyway
                }
            } else {
#               $j = [Int]0
#               $len = $fnames.Count
#               $len_check = $start_a.Count
#               if ($len -ne $len_check) {
#                   ECHO "Something's wrong with the array lengths of $start_a or $fnames!"
#                   return -1
#               }
                # we don't need to recurse anymore, since we have the file names here and we can revert them!
                if ([System.IO.File]::Exists($start_a[0] + ".savecfg")) {
                    $save_cfg = [Boolean]1
                } else {
                    $save_cfg = [Boolean]0
                }
                if ($save_cfg) {
                    # We can't have the following characters in filenames: \ / : * ? " < > |
                    $server_dir = $server -Replace '[\\/:*?"<>|]', ""
                    $f_noQ = Split-Path $start_a[0] -NoQualifier
                    $newpath = $PSScriptRoot + "\TMP-Confs\" + $f_noQ
                    New-Item -ItemType Directory -Force -Path $newpath
                    $locked = Test-FileLock $start_a[0] + $fnames[0]
                    if (-not $locked) {
                        Move-Item -Force ($start_a[0] + $fnames[0]), ($newpath + $fnames[0])
                        Rename-Item -Force ($newpath + $fnames[0]), ($newpath + $server_dir + "-" + $fnames[0])
                    } else {
                        # Not sure what I should do
                        ECHO "File is locked at first part! (moving to new path and renaming)"
                    }
                }
                $locked = Test-FileLock $start_a[0] + "orig-" + $fnames[0]
                    if (-not $locked) {
                        Rename-Item -Force ($start_a[0] + "orig-" + $fnames[0]), ($start_a[0] + $fnames[0])
                    } else {
                        # Not sure what I should do
                        ECHO "File is locked at first part! (renaming to old filename)"
                    }
                ForEach ($file in $rev_files) {
                    # We still have to get the filename by itself, heh
                    $fname = Split-Path $file -Leaf
                    $fdir = $file -Split $fname
                    $fdir = $fdir[0]
                    if ($save_cfg) {
                        # TODO: if $sub_ini is off, the current script forces us to look in the cluster directory for this file
                        $f_noQ = Split-Path $file -NoQualifier
                        $f_noQ = $f_noQ -Split $fname # $tmp =
                        #$f_noQ = $tmp[0]
                        $newpath = $PSScriptRoot + "\TMP-Confs\" + $f_noQ
                        New-Item -ItemType Directory -Force -Path $newpath
                        $locked = Test-FileLock $newpath + $fname
                        if (-not $locked) {
                            Move-Item -Force $file, ($newpath + $fname)
                            Rename-Item -Force ($newpath + $fname), ($newpath + $server_dir + "-" + $fname)
                        } else {
                            # Not sure what I should do
                            ECHO "File is locked at loop save_cfg part! (renaming to new path and renaming)"
                        }
                    }
                    $locked = Test-FileLock $fdir + "orig-" + $fname
                    if (-not $locked) {
                        # Now, rename the file to its original name
                        Rename-Item -Force ($fdir + "orig-" + $fname), ($file)
                    } else {
                        # Not sure what I should do
                        ECHO "File is locked at loop part! (renaming to old filename)"
                    }
                }
            }
        } else {
            # THIS PART IS NOT COMPLETE!  Might move to a new function, if anything.
            $cmd_edits = "" # Scan each command into the $cmd_edits Parameter.
            $i = [Int]0
            $len = $fnames.Count
            $len_check = $start_a.Count
            if ($len -ne $len_check) {
                ECHO "Something's wrong with the array lengths of $start_a or $fnames!"
                return -1
            }
            While ($i -ne $len) {
                $lines = ""
                # Now go line by line
                Get-Content ($start_a[$i] + $fnames[$i]) -ReadCount 1 | ForEach-Object {
                    if ($_ -ne "") {
                        $line = $_ -Replace "%ZANMANDIR%", $PSScriptRoot -Replace "%SERVER%", "$server" -Replace "%ZANDIR%", "$zandir"
                        if ( (-not ($_ -Match "^//.*")) -and (-not ($_ -Match "^SV_MOTD.*")) ) {
                            # We can't have backslashes!
                            $line = $line -Replace "\\", "/"
                        }
                        if ($line -Match "exec .*") { # found a Match, or last layer
                            if ($layer -ne 1) {
                                $new_cfg = $line -Replace "exec ", "" -Replace '"', "" -Replace ";", "" -Replace "\\", "/"
                            }
                            if ($layer -eq 4) {
                                $rev_files[0] = $new_cfg
                            } else {
                                if ($layer -ne 1) {
                                    # layer 1 will not have any new cfg files - they are the bottom layer.
                                    $rev_files += $new_cfg
                                }
                            }
                        }
                        $lines = $lines + $line -Replace ";", ""
                    }
                }
                $i = $i + 1
                $cmd_edits = $cmd_edits + $lines
            }
            $layer = $layer - 1
            if ($layer -ne 3) {
                if ($old_rev_files.Count -ne [Int]1) {
                    $i = 0 # $i is already initialized as an [Int]
                    # Inspiration source for next line of code: https://stackoverflow.com/questions/47387016/array-subtraction-in-powershell
                    $new_cfg_a = $rev_files | Where-Object {$_ -notin $old_rev_files}
                    $len = $new_cfg_a.Count
                    $new_cfg_fnames = New-Object String[] $len
                    $new_cfg_paths = New-Object String[] $len
                    While ($i -ne $len) {
                        $new_cfg_fnames[$i] = Split-Path $new_cfg_a[$i] -Leaf
                        $fdir = $new_cfg_a[$i] -Split $new_cfg_fnames[$i]
                        $new_cfg_paths[$i] = $fdir[0]
                        $i = $i + 1
                    }
                } else {
                    # Inspiration source for next line of code: https://stackoverflow.com/questions/18018892/pick-last-item-from-list-in-powershell
                    $new_cfg_a = $rev_files | Select-Object -Last 1
                    $new_cfg_fnames = @("")
                    $new_cfg_paths = @("")
                    $new_cfg_fnames[0] = Split-Path $new_cfg_a -Leaf
                    $fdir = $new_cfg_a -Split $new_cfg_fnames[0]
                    $new_cfg_paths[0] = $fdir[0]
                }
            } else {
                $new_cfg_fnames = @("")
                $new_cfg_paths = @("")
                $new_cfg_a = $rev_files
                $new_cfg_fnames[0] = Split-Path $new_cfg_a -Leaf
                $fdir = $new_cfg_a -Split $new_cfg_fnames[0]
                $new_cfg_paths[0] = $fdir[0]
            }
            $cmd_edits += Parse_ZanCFG $new_cfg_paths $server $new_cfg_fnames $zandir $greedy $revert $cmd $rev_files $layer $grabbed_fullname $full_title $stripped
        }
    }
    
    function Parse-ZanCMD
    {
        Param( [String] $start, [String] $cmd, [String[]] $config_a, [String] $zandir, [String] $iwaddir, [String] $pwaddir, [Boolean] $greedy, [String] $cust_fold = "", [String] $cust_cfg = "" )
        # Runs Zandronum.
        #   The good news is that we have the entire command string, $cmd.
        #     Unfortunately, it needs to be properly parsed.  And, we have to modify the configuration file.
        #   $cmd = `$cmd_begin $SERVER-IWAD[ %:PREPEND_ALL:%] $SERVER-FILES[ %:APPEND_ALL:%][ %:greedy:%]`n[...]`n%:%`n[$SERVER-NAME] [...]
        
        # Here's the easy part.
        $cmd = $cmd -replace "%IWADDIR%", $iwaddir
        $cmd = $cmd -replace "%PWADDIR%", $pwaddir

        if ([System.IO.File]::Exists($start + ".do_not_host")) {
            # Looks like we're not actually running this cluster.
            return 1
        }

        $cmd, $SERVERS = $cmd.split(";;")

        $c_cnt = $cmd.Split("`n").GetUpperBound(0)
        $s_cnt = $SERVERS.Split("`n").Length - 23 # TODO: find a way to remove those newlines [DONE]

        # These two strings should Match pairwise due to the way it was generated
        $S_Array = $SERVERS.Split("`n")
        $spc1 = $S_Array[0]
        $spc2 = $S_Array[($S_Array.Length - 1)]
        $new_uppbnd = $S_Array.Length - 2
        $S_Array = $S_Array[1..$new_uppbnd]
        $s_cnt = $S_Array.Length

        if (($spc1 -ne "") -or ($spcs2 -ne "")) {
            # how did you get here?
            ECHO "How did you remove the first and last newlines?"
        }
        
        if ($s_cnt -eq $c_cnt) {
            $start_a = New-Object String[] $s_cnt
            if ($s_cnt -eq 1) {
                $S_Array = @($S_Array)
                $start_a[0] = $start
                Run-ZanServer $cmd $start_a[0] $S_Array[0] $config_a[0] $zandir $greedy $cust_fold $cust_cfg
            } else {
                $i = [Int]0
                $config = New-Object String[] $c_cnt
                $cmd_a = New-Object String[] $c_cnt
                $cmd_a = $cmd.Split("`n")
                While ($i -lt $c_cnt) {
                    if ($i -eq 8)
                    {
                        ECHO "We are here!"
                    }
                    $j = [Int]0
                    $len = $config_a.Length
                    While ($j -lt $len) {
                        $start_a[$i + $j] = $start
                        $config[$i + $j] = $config_a[$j]
                        $custom = Run-ZanServer $cmd_a[$i + $j] $start_a[$i + $j] $S_Array[$i + $j] $config[$i + $j] $zandir $greedy $cust_fold $cust_cfg
                        if ($custom) {
                            # The user elected to run a custom cfg.  So, we'll end the loop.
                            $j = $len
                        } else {
                            $j = $j + 1
                        }
                    }
                    $i = $i + $len
                    
                }
            }
        } else {
            # Not sure how this happened.
            ECHO "Error with the script.  Cannot properly Match server name(s) with its corresponding command."
            return -1
        }
    }

    function Run-ZanServer
    {
        Param ( [String] $cmd, [String[]] $start, [String] $server, [String[]] $config, [String] $zandir, [Boolean] $greedy, [String] $cust_fold = "", [String] $cust_cfg = "" )
        # Runs Zandronum Server.
        #   Parses the CFG file into a sandbox directory structure and runs the server.
        $runs_custom = [Boolean]0
        $error = [Boolean]0
        if ($cmd -Match ".*%CUST%.*") {
            # User has elected to run their own cfg.  It will still use the other sandboxed cfg files, but we start from this one.
            #   NOTE: Right now, this is not really doing anything with respect to what the user put in.  The script takes care of it!
            $cmd = $cmd -Replace "%CUST% ", ""
#           $cmd = $cmd -Replace "%SUBCLUSTER%", $start
#           $cmd = $cmd -Replace "%CLUSTER%", $start
#           $cmd = $cmd -Replace "/", "\"
            $runs_custom = [Boolean]1
            if ($cust_cfg -eq "") {
                # This is not good.
                ECHO "So, we detected you had a custom .cfg file in the command, but there was no custom CFG file in your subcluster."
                ECHO "cmd = " + $cmd
                $error = [Boolean]1
            }
        } else {
            $runs_custom = [Boolean]0
        }
        if ((-not $greedy) -and (-not $error)) {
            $revert = [Boolean]0
#           $rev_files = Parse_ZanCFG $start $server $config $zandir $greedy $revert
#           $revert = [Boolean]1
#           Parse_ZanCFG $start $server $config $zandir $greedy $revert $rev_files
            #Start-Sleep -s 2
            if ($runs_custom) {
                # Last two variables are passed in as a single string, not an array.
                $start = @("")
                $config = @("")
                $start[0] = $cust_fold + "\" # TODO: Check whether or not there's not a trailing slash at the end? (DONE)
                $config[0] = $cust_cfg
            }
            $full_title = Parse_ZanCFG $start $server $config $zandir $greedy $revert
            Start-Sleep -s 2
            # We can't have the following characters in filenames: \ / : * ? " < > |
            $server_dir = $server -Replace '[\\/:*?"<>|]', ""
            $folderpath = $PSScriptRoot + "/TMP-Confs/" + $server_dir + "/"
            $server_info = $full_title[$full_title.Length - 1] -Replace "^(.+[^%])%LOGFILENAME%([^%].+)$", '$1' -Replace '[\\/:*?"<>|]'. ""
            $fixedpath = $folderpath -Replace $server_dir, $server_info # TODO: Find out why it's index 17 heh (DONE)
#           Move-Item -Force $folderpath, $fixedpath
            $cmdPATH = ($PSScriptRoot + "\" + $server_dir + ($start.Substring($PSScriptRoot.Length))) #-Replace "(^.+\\)[^\\]+\\$", '$1'
            $bwd = [Boolean]1
            $cmd = Replace-CMDPATH $cmd $cmdPATH $bwd
        }
        if ($greedy -and (-not $error))  {
            Start-Sleep -s 2
            $cmd = Parse_ZanCFG $start $server $config $zandir $greedy [Boolean]0 $cmd
            Start-Sleep -s 2
        }
        $log_file = $full_title[$full_title.Length - 1] -Replace "^(.+[^%])%LOGFILENAME%([^%].+)%LOGFILENAME%$", '$2'
        # $cmd = $cmd -Replace "%SERVER%", folderpath -Replace ".*(\\\.cfg)", '$(1)')$(1)') # TODO: Check also if %SERVER% exists?
        # Sorry.  I just couldn't get it to work in the .cfg file on the Cluster level if Subcluster existed.  :(
        #   On the bright side, have a look at this awesome regex that I probably could have used elsewhere!
        # (just a note, because SV_HostName is in there twice, it adds %LOGFILENAME% to the end.  So, I had to take that out too.)
        #$cmd = $cmd + " +LogFile " + '"' + $log_file + ".log" + '"'
        #$cmd = $cmd -Replace "(\+exec.*\.cfg.) (-LogFile.*\.log.)", '$2 $1'
        if (-not $error) {
            Invoke-Expression $cmd
        } else {
            ECHO "Command not run.  There was an error with your custom configuration file."
        }
        Start-Sleep -s 3
        # This next line's source is:
        #   https://stackoverflow.com/questions/14608614/why-is-powershells-move-item-deleting-the-destination-directory
        Try {
            [System.IO.Directory]::Move($folderpath, $fixedpath)
        } Catch [System.IO.IOException] {
            # TODO: Check folder byte size to see that it Matches.  Right now, I'm trusting the program!
            Remove-Item -Recurse -Path "$folderpath\*"
        }
        return $runs_custom
    }

    function Run-ZanSubCluster
    {
        Param( [String] $start, [String] $subcluster, [String] $cluster_ini_file, [String] $zandir, [String] $iwaddir, [String] $pwaddir, [Boolean] $greedy, [Boolean] $use_opt )
        # This function will scan the subcluster directory for:
        #     -Symbolic Links (in this case, $use_opt will tell us whether or not to ignore it)
        #     -a .donothost file
        #     -the proper .cfg file to host
        #     -a servers.ini file which means not using the cluster's .ini
        #
        # $use_opt [Boolean]1 means that symbolically linked folders will either APPEND or PREPEND some files (typically not both)
        #
        # .donothost must be searched FIRST because if it's there, we do not run the rest of this function.
        $prepend_list = ""
        $append_list = ""
        $cmd_servers = ""
        $uses_customcfg = [Boolean]0

        if ([System.IO.File]::Exists($start + $subcluster + ".donothost")) {
            return 1
        }

        if (-not $use_opt) {
            # Having .use_opt in the parent directory will be a global setting for ON.
            if ([System.IO.File]::Exists($start + $subcluster + ".useopt")) {
                $use_opt = [Boolean]1
            }
        }

        Get-ChildItem -Directory -Path ($start + $subcluster) | ForEach-Object {
            if (-not $_) { # No folders
                if ($use_opt) {
                    ECHO "A subcluster folder was found in $ZANMAN/Cluster with use_opt true, but no folders were found.  Did you forget to remove the global .useopt setting?  Turning off optional...."
                    $use_opt = [Boolean]0
                }
            } else {
                $folder = $_.Name + "\"
                if ($_.Attributes -Match "ReparsePoint") {
                    # a symbolic link - let's get the file info now
                    Get-ChildItem -file -Path ($start + $subcluster + $folder) | ForEach-Object {
                        # for now, there should only be just one file (an .ini file)
                        $file = $_.Name
                        $append = [Boolean]0
                        $prepend = [Boolean]0
                        switch -regex ($file) {
                            ".+\.ini" {
                                Get-Content ($start + $subcluster + $folder + $file) | ForEach-Object {
                                    # Now, grab the variables
                                    switch -regex ($_) {
                                        "PREPEND_ALL::" {
                                            $prepend = [Boolean]1
                                        }
                                        "APPEND_ALL::" {
                                            $append = [Boolean]1
                                        }
                                        "-file.*" {
                                            if ($prepend) {
                                                $prepend_list = $prepend_list + $_ + " "
                                            }
                                            if ($append) {
                                                $append_list = $append_list + $_ + " "
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    # These should be optional configs to use (NOTE: only one supported atm)
                    ECHO "If you're using a physical folder for custom .cfg files, then ignore this warning.  Remember to point to it in your .ini file!"
                    ECHO "Know that only one custon .cfg file is supported right now."
                    $cust_fold = $_.FullNAme
                    Get-ChildItem -file -Path ($start + $subcluster + "\" + $_) | ForEach-Object {
                        Switch -regex ($_) {
                          ".*\.cfg" {
                              $uses_customcfg = [Boolean]1
                              $cust_cfg = $_.Name
                          }
                        }
                    }
                }
            }
        }
        # now load file from subcluster
        $grabbed_ini = [Boolean]0
        $grabbed_cfg = [Boolean]0
        $runs_cluster_ini = [Boolean]0
        $ini_fname = ""
        $hostdup = [Boolean]0
        $cfg_file_a = New-Object String[] 1
        $i = [Int] 0
        Get-ChildItem -file -Path ($start + $subcluster) | ForEach-Object {
            if (-not $_) { # No files - not good
                ECHO "A subcluster was found in $ZANMAN/Cluster but no files were found.  Did you forget to add configuration files (.cfg, symbolic links to .optional wads, .useopt file, etc.?)"
                return -1
            }
            switch -regex ($_) {
                ".*\.ini" {
                    # ini file for subcluster.
                    $grabbed_ini = [Boolean]1
                    $ini_fname = $_.Name
                }
                ".*\.cfg" {
                    # configuration file.  This is what we need to run Zandro!
                    if (-not $grabbed_cfg) {
                        $grabbed_cfg = [Boolean]1
                        $cfg_file_a[0] = $_.Name
                    } else {
                        $i = $i + 1
                        $tmp = New-Object String[] ($i + 1)
                        $j = [Int] 0
                        While ($j -lt $cfg_file_a.Length) {
                            $tmp[$j] = $cfg_file_a[$j]
                            $j = $j + 1
                        }
                        $tmp[$j] = $_
                        $cfg_file_a = $tmp
                    }
                }
                "\.useclusterini" {
                        # user has opted not to use the subcluster ini
                        $runs_cluster_ini = [Boolean]1
                        $ini_fname = $cluster_ini_file
                        $grabbed_ini = [Boolean]1 # Even though we didn't technically grab anything, this still needs to be set to true.  TODO: Check if cluster .ini exists?
                }
                "\.hostdup" {
                    # This basically means that there are two or more duplicates that the user wants to host with the same servers.ini
                    $hostdup = [Boolean]1 # TODO: currently, the program _always_ runs duplicates regardless of bool value.  Need to make an input optional for the user on which one(s) to host if no .hostdup
                    ECHO "This function is currently unsupported. [.hostdup]"
                }
            }
        }
        if ($grabbed_ini) {
            if ($runs_cluster_ini) {
                $ini_path = $start + $ini_fname
            } else {
                $ini_path = $start + $subcluster + $ini_fname
            }
#           $cfg_path = $start + $subcluster + $cfg_file
            if (-not $uses_customcfg) {
                $cmd_servers = Build-CMDList $ini_path $cfg_file_a $zandir $greedy $use_opt
            } else {
                $cmd_servers = Build-CMDList $ini_path $cfg_file_a $zandir $greedy $use_opt $cust_cfg
            }
            if ($cmd_servers -ne 0) {
                if ($use_opt) {
                    if ($prepend) {
                        $cmd_servers = $cmd_servers -Replace "%:PREPEND_ALL:%", $prepend_list
                    } else {
                        $cmd_servers = $cmd_servers -Replace "%:PREPEND_ALL:%", ""
                    }
                    if ($append) {
                        $cmd_servers = $cmd_servers -Replace "%:APPEND_ALL:%", $append_list
                    } else {
                        $cmd_servers = $cmd_servers -Replace "%:APPEND_ALL:%", ""
                    }
                }
                $start_new = $start + $subcluster
                if (-not $uses_customcfg) {
                    Parse-ZanCMD $start_new $cmd_servers $cfg_file_a $zandir $iwaddir $pwaddir $greedy
                } else {
                    Parse-ZanCMD $start_new $cmd_servers $cfg_file_a $zandir $iwaddir $pwaddir $greedy $cust_fold $cust_cfg
                }
            } else {
                ECHO "Nothing was in the subcluster .ini file!"
            }
        } else {
            ECHO "No .ini file was found.  Please make an .ini file for your subcluster, or specify .useclusterini"
            return -1
        }
    }
    
    function Search-ClusterConf
    {
        Param( [String] $start, [String]$zandir, [String]$iwaddir, [String]$pwaddir )
        $cmd_servers = ""
        $subclusters = [Boolean]0
        $use_opt = [Boolean]0

        # check if there's actually files first.
        Get-ChildItem -File -Path $start | ForEach-Object {
            if (-not $_) { # No files - not good
                ECHO "No files were found in " + $start + " but no files were found.  Did you forget to add configuration files (.cfg, .ini, etc.?)"
                return -1
            }
            switch -regex ($_) {
                ".*\.cfg" {
                    $cfg_file = $_.Name
                    # configuration file.  This is what we need to run Zandro!
                }
                ".*\.ini" {
                    $ini_file = $_.Name
                    # ini file.  This is what is used to build the CMD.
                }
            }
        }

        if ([System.IO.File]::Exists($start + ".subclusters")) {
            # There will be subclusters
            $subclusters = [Boolean]1
        }
        if ([System.IO.File]::Exists($start + ".useopt")) {
            # Will be using ".optional" folder
            $use_opt = [Boolean]1
        }

        if ($subclusters) {
            if ((-not [System.IO.Directory]::Exists($start + ".optional")) -and ($use_opt)) {
                # User suggested .useopt when no .optional folder exists
                ECHO ".optional is asked to be used, but no .optional folder is found.  Disabling optional..."
                $use_opt = [Boolean]0
            }
            Get-ChildItem -Directory -Path $start | ForEach-Object {
                $folder = $_
                if (-not $folder) { # No folders
                    ECHO "No folders found in Cluster, but .subclusters was enforced."
                } else {
                    $subcluster_dir = $folder.Name + "\"
                    if ($subcluster_dir -ne ".optional\") {
                        # Time to scan the Sub-Cluster
                        $greedy = [Boolean]0
                        Run-ZanSubCluster $start $subcluster_dir $ini_file $zandir $iwaddir $pwaddir $greedy $use_opt
                    }
                }
            }
        } else {
            # Parsing the CFG has two "solutions".
            #
            # 1. (The less resource-hogging method): Recursively edit the physical .cfg file with piped input every time it's ran.
            #                                        (and between each run, remember to properly revert the changes for the mext server)
            $greedy = [Boolean]0
            # 2. (The memory hog): Load the entire cfg recursively into one variable, then output it either to a temporary file or pipe it into $cmd literally line by line.
            #                      Makes room for more complicated parsing in Python later on, but comes at the cost of being a very greedy implementation in Powershell especially.
#           $greedy = [Boolean]1
            $ini_loc = $start + $ini_file
            $cfg_loc = $start + $cfg_file
            $cfg_file_a = @($cfg_file) # TODO: add support for multiple cfg files in cluster folder
            $cmd_servers = Build-CMDList $ini_loc $cfg_file_a $zandir $greedy $use_opt
            # Run the cluster!
            if ($cmd_servers -ne [Int]0) {
                Parse-ZanCMD $start $cmd_servers $cfg_file_a $zandir $iwaddir $pwaddir $greedy
            } else {
                ECHO "Nothing was in the cluster .ini file!"
            }
        }
    }

    function Build-CMDList
    {
        Param( [String] $start, [String []] $cfg_file_a, [String] $ZANDIR, [Boolean] $greedy, [Boolean] $use_opt, [String] $cust_cfg = "" )
        # Builds a list of commands, separated by '`n', to run each server in the cluster.

        $cfg_path = $cfg_path -Replace "\\", "/"
        $specified_iwad = "-iwad " + '"' + "%IWADDIR%/DOOM2.WAD" + '"'
        $line = ""
        # okay, this is annoying but we don't want a trailing space at the front of $SERVERS
        $firstserver = [Boolean]1

        # further, we have to collect the command so that each time $ZANDIR + "Zandronum.exe -host -port [port]" is always the beginning of each command
        $cmd_begin = $ZANDIR + "/Zandronum.exe" + " " + "-host" + " " + "-port" + " " + "60089" # TODO: port needs to be a CCMD
        $server_command = ""
        $SERVERS = ""
        $collect_line = [Boolean]0
        $empty = [Boolean]0

        # lastly, get a complete, ordered, list of server names to return for future parsing
        Get-Content ($start) | ForEach-Object {
            if (-not ($_ -Match "^//.*")) { # servers to ignore must currently be on all lines that don't want to be processed, and have to be "//" at the start of the line.
                # Loop line by line
                if ($_ -Match "EMPTY") {
                   $empty = [Boolean]1
                }
                if ($_ -Match ".+::") {
                    # Collect %SERVER%
                    if (-not $firstserver) {       
                        if ($use_opt) {
                            # The user is hosting subclusters, so add a parsable marker
                            $line = " %:PREPEND_ALL:%" + $line + " %:APPEND_ALL:%"
                        }
                        $len = $cfg_file_a.Length
                        $i = [Int]0
                        While ($i -lt $len) {
                            $server_command = $server_command + $cmd_begin + " " + $specified_iwad + $line
                            if ($greedy) {
                                # The user has elected to place all configuration information in the command itself.
                                #
                                # Thus, we have to add a parsable marker so that this can be done properly.
                                $server_command = $server_command + " %:greedy:%" + "`n"
                            } else {
                                if (-not $runs_custom_exec) {
                                    $server_command = $server_command + " +exec " + '"%PATH%' + $cfg_file_a[$i] + '"' + "`n"
                                } else {
                                    if ($cust_cfg -eq "") {
                                        # Not sure what happened here
                                        ECHO "Looks like you have a custom CFG in your .ini file, but we're not getting a custom CFG filename!"
                                        $server_command = $server_command + " +exec " + '"%PATH%' + $cfg_file_a[$i] + '"' + "`n"
                                    } else {
                                        $server_command = $server_command + " +exec " + '"%PATH%' + $cust_cfg + '"' + "`n"
                                        $runs_custom_exec = [Boolean]0
                                    }
                                }
                            }
                            $SERVERS = $SERVERS + $_ -replace "::", "`n" #-replace "`n", " "
                            $i = $i + 1
                        }
                        $line = ""
                        $specified_iwad = "-iwad " + '"' + "%IWADDIR%/DOOM2.WAD" + '"'
                    } else {
                        $len = $cfg_file_a.Length
                        $i = [Int]0
                        While ($i -lt $len) {
                            # first server found, so no command to be added to $server_command yet
                            $SERVERS = $SERVERS + $_ -replace "::", "`n" #-replace "`n", " "
                            $firstserver = [Boolean]0
                            $i = $i + 1
                        }
                    }
                } if ($_ -eq "`n") {
                    # New Line
                    ECHO "Not parsing because it's just a newline"
                } else {
                    switch -regex ($_) { # TODO: make the regex Matches slightly more lenient?
                        "-iwad.+" {
                            # found the iwad
                            $specified_iwad = $_ -replace "`n", "" # pretty sure I don't need to replace anything here
                        }
                        "-file.+" {
                            # append line to command (it's mostly garbage until we parse it)
                            $line = $line + " " + $_ -replace "`n", "" # pretty sure I also don't need that replace here
                        }
                        ".exec.+" {
                            $runs_custom_exec = [Boolean]1
                            # in this case, the user wants to load a different configuration file...
                            #   Technically, it doesn't really matter what the user actually puts here.
                            $line = $line + " " + "%CUST%"
    #                       $line = $line + " " + $_ -replace "`n", "" -replace "/", "" -replace "\\", ""
                        }
                        "%CUST%" {
                            $runs_custom_exec = [Boolean]1
                            #   I should point out that if the script, as it currently does, simply neglects the actual
                            #     path and filename that the user provides, that will limit us to one custom cfg per
                            #     cluster/subcluster.  It might be OK, since by design you can make as many subclusters as
                            #     you want.  But, it will be no doubt confusing....  Example, Cyber's RJ Extreme uses Skulltag
                            #     jump physics but I still want to put it with the oldschool RJ server subcluster.
                            #  
                            #  Right now, the script will find the singular file by itself..... and it doesn't really check how many
                            #    it fetches, I don't think?
                            $line = $line + " " + $_
                        }
                    }
                }
            }
        }
        if ($empty) {
            return [Int]0
        # We have reached the end of the file and we must append what we have left.
        }
        if ($use_opt) {
            # The user is hosting subclusters, so add a parsable marker on the last line
            $line = " %:PREPEND_ALL:%" + $line + " %:APPEND_ALL:%"
        }
        $len = $cfg_file_a.Length
        $i = [Int] 0
        While ($i -lt $len) {
            if ($greedy) {
                # Thus, we have to add a parsable marker on the last line for $greedy = True
                $server_command = $server_command + $cmd_begin + " " + $specified_iwad + $line + " +exec " + '"%PATH%' + $cfg_file_a[$i] + '" %:greedy:%' + "`n"
                # NOTE: If there's a custom configuration file, this line will not really matter.  So, no need to change it!
            } else {
                $server_command = $server_command + $cmd_begin + " " + $specified_iwad + $line + " +exec " + '"%PATH%' + $cfg_file_a[$i] + '"' + "`n"
            }
            $i = $i + 1
        }
        return $server_command + ";`n" + $SERVERS # we need to have a Matchable separator for .cfg parsing
    }
    
    function Scan-ClustersDirectory
    {
        Param( [String]$start, [String]$zandir, [String]$iwaddir, [String]$pwaddir )
        ### Check directories first.
        ##
        #   Directory = Cluster Configuration with .cfg file.

        Get-ChildItem -Directory -Path $start | ForEach-Object {
            $cluster_dir = $start + $_.Name + "\"
            Search-ClusterConf $cluster_dir $zandir $iwaddir $pwaddir
        }
    }

    function main
    {
        # Create variables to store paths
        $zandir = ""
        $iwaddir = ""
        $pwaddir = ""

        # Get the values in settings.ini
        Get-Content ($PSScriptRoot + "\settings.ini") | ForEach-Object {
            # Parse lines
            switch -regex ($_){
                "%ZANDIR% =.*" {
                    $zandir = $_ -Replace "%ZANDIR% = ", ""
                    $zandir = $zandir -Replace "\\", "/"
                }
                "%IWADDIR% =.*" {
                    $iwaddir = $_ -Replace "%IWADDIR% = ", ""
                    $iwaddir = $iwaddir -Replace "\\", "/"
                }
                "%PWADDIR% =.*" {
                    $pwaddir = $_ -Replace "%PWADDIR% = ", ""
                    $pwaddir = $pwaddir -Replace "\\", "/"
                }
            } # TODO: Check for a slash at the end of the line; if it's there, omit it from the parsed string
        }
        
        if ( ($zandir -eq "") -or ($iwaddir -eq "") -or ($pwaddir -eq "") ) {
            # Error!
            ECHO "Please check to make sure that your settings.ini file contains the directories of Zandronum, IWAD files, and PWAD files (and be sure to omit the slash at the end.)"
            return -1
        }
        $start = $PSScriptRoot + "\Clusters\"
        # I definitely do not want to have to pass in these bloody variables in all these functions that don't need it!  Thus, it needs to become part of a class object.
        Scan-ClustersDirectory $start $zandir $iwaddir $pwaddir
    }

    #Entry point
    main
}


Invoke-Command -Scriptblock $script -Verbose
