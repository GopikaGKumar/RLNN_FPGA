# ----------------------------------------------------------------------
# Copyright (c) 2009 by Cadence Design Systems, All Rights Reserved
# 
# This software is provided as is without warranty of any kind.  The 
# entire risk as to the results and performance of this software is 
# assumed by the user.
#
# Cadence Design Systems disclaims all warranties, either express or 
# implied, including but not limited, the implied warranties of 
# merchantability, fitness for a particular purpose, title and
# noninfringement, with respect to this software.
# ----------------------------------------------------------------------
#
# File: create_mmap.tcl
#
# Example usage:
#    Add "source create_mmap.tcl" to your .simvisionrc file
#    in the current directory or in your home directory.
#
# -----------------------------------------------------------------;

# This TCL file defines a mechanism for users to create
# a new SimVision mnemonic map for any given Verilog state variable
# and the localparams / parameters that make up its state enumerations.
#
# The created mmap is named with the concatenation of the
# Verilog module and the FSM state variable, to make it unique.
#
# Any enumeration name that contains "ERROR" or "error" will result
# in a mmap line coloured red, to highlight error conditions.
# You can extend this concept freely, just adapt this script!
#
# Select the state variable and the associated localparams in the
# DesignBrowser window, then click the "FSM Map" button on the toolbar.
# The mmap will be created, the state signal will be sent to the
# waveform window (and a new waveform created if necessary).
# The mmap should be automatically applied to the state signal.

proc create_mmap { } {

  set args [select get -type signal]
  puts "create_mmap $args"
  if { [llength $args] < 2 } {
    tk_messageBox -title "SimVision - Error" -icon error -type ok \
      -message "At least 2 HDL objects must be selected;\none FSM state variable and one or more parameter/localparam enumeration values"
    return
  }

  set name "New FSM Map"
  set enums ""

  set gotstate 0

  foreach arg [split $args " "] {
    ## Remove Verilog range declarations like "[1:0]"
    regsub -all {\[.*\]} $arg "" arg
    ## Remove enclosing curly braces if present
    regsub -all {[{}]} $arg "" arg

    ## get and check the object type
    ## should be "variable" for state reg or "parameter" for enums
    set descr [ console submit -using simulator "describe $arg" ]
    set type  [ lindex [ split $descr " " ] 0 ]
    set type  [ lindex [ split $type "." ] end ]

    if {$type == "variable"  || $type == "output" || $type == "input" } {
      if {$gotstate == 1} {
        tk_messageBox -title "SimVision - Error" -icon error -type ok \
          -message "More than one state variable was selected; the first variable '$statevar' will be used to name the mmap."
      } else {
        ## Record which item is the state variable
        set statevar $arg

        ## Find the name of the enclosing Verilog module
        regsub {.[a-zA-Z0-9_]+$} $statevar "" modinst
        #simulator: set module [ lindex [ split [ describe $modinst ] " " ] end ]
        set mdescr [ console submit -using simulator "describe $modinst" ]
        set module [ lindex [ split $mdescr " " ] end ]
        regsub "\n" $module "" module

        ## Set the mmap's name from the module name and state variable name
        set name [ lindex [ split $arg "." ] end ]
        set name "${module}__${name}"

        puts "Creating new mmap for state variable $statevar"
        puts "Setting new mmap name = $name"

        set gotstate 1
      }
    } elseif {$type == "parameter"} {
      ## Extract enum values
      set val [ lindex [ split $descr " " ] end ]
      regsub "\n" $val "" val
      regsub {\d+'[hdbo]} $val "" val
      set lbl [ lindex [ split $arg "." ] end ]
      regsub "\n" $lbl "" lbl

      ## Check enum name to apply any extra formatting
      if { [regexp {ERROR|error} $lbl] } {
        append enums "  {%x=$val -label $lbl -linecolor red -textcolor red}\n"
      } else {
        append enums "  {%x=$val -label $lbl}\n"
      }
    } else {
      tk_messageBox -title "SimVision - Error" -icon error -type ok \
        -message "Object $arg is a '$type' not a Verilog variable nor a parameter; it will be ignored."
    }
  }

  # Determine target waveform window.
  set win ""
  foreach w [window find -type waveform] {
    if {[waveform target -using $w]} {
      set win $w
      break
    }
  }

  # If no target waveform window, create one.
  if {$win == ""} {
    set win [waveform new]
  }

  window activate $win

  ## TODO: handle enum values that are not hex literals
  mmap new -reuse -name $name -radix %x -contents $enums

  ## Automatically add the fsm state variable to the waveform
  ## and apply the mmap
  set id [waveform add -signals $statevar -using $win]
  waveform format $id -radix $name

  set fname $name.svcf
  set fh [open $fname w]
  set simviscmd "mmap new -reuse -name $name -radix %x -contents {\n"
  append simviscmd "$enums"
  append simviscmd "}\n"
  puts $fh "$simviscmd"
  close $fh
  puts "Wrote mnemonic map to file '$fname' - use this in future to restore the mmap directly"

}

# This adds the marker button to all Waveform windows
window extensions button create -type browser CreateFSMMap \
    -label "FSM Map" \
    -help "Create FSM mnemonic map from selected signal and localparams" \
    -command {create_mmap}

puts "Loaded create_mmap function"

