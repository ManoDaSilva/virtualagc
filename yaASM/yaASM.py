#!/usr/bin/python3
# Copyright 2019 Ronald S. Burkey <info@sandroid.org>
#
# This file is part of yaAGC.
#
# yaAGC is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# yaAGC is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with yaAGC; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Filename:    yaASM.py
# Purpose:     An LVDC assembler, intended to replace yaASM.c for LVDC
#              (but not for OBC) assemblies.  It's actually just something
#              I'm playing around with to see if I can get something a
#              little cleaner and thus easier for me to maintain than yaASM.c, 
#              so I shouldn't really say I _intend_ it as a replacement.
# Reference:   http://www.ibibio.org/apollo
# Mods:        2019-07-10 RSB  Began playing around with the concept.
#
# The usage is just
#              yaASM.py <INPUT.lvdc >OUTPUT.listing
# If the assembly is successful, an executable file for the assembler is 
# output, called lvdc.bin.

import sys
# The next line imports expression.py.
import expression

operators = {
    "HOP": { "opcode":0b0000 }, 
    "HOP*": { "opcode":0b0000 }, 
    "MPY": { "opcode":0b0001 }, 
    "SUB": { "opcode":0b0010 }, 
    "DIV": { "opcode":0b0011 }, 
    "TNZ": { "opcode":0b0100 }, 
    "MPH": { "opcode":0b0101 }, 
    "AND": { "opcode":0b0110 }, 
    "ADD": { "opcode":0b0111 },
    "TRA": { "opcode":0b1000 }, 
    "XOR": { "opcode":0b1001 }, 
    "PIO": { "opcode":0b1010 }, 
    "STO": { "opcode":0b1011 }, 
    "TMI": { "opcode":0b1100 }, 
    "RSU": { "opcode":0b1101 }, 
    "CDS": { "opcode":0b1110, "a9":0 }, 
    "SHF": { "opcode":0b1110, "a9":1, "a8":0 }, 
    "EXM": { "opcode":0b0000, "a9":1, "a8":0 },
    "CLA": { "opcode":0b1111 }, 
    "SHR": { "opcode":0b1110, "a9":1, "a8":0 }, 
    "SHL": { "opcode":0b1110, "a9":1, "a8":0 }
}
pseudos = []

lines = sys.stdin.readlines()
for n in range(0,len(lines)):
	lines[n] = lines[n].rstrip()


#----------------------------------------------------------------------------
#	Preprocessor pass
#----------------------------------------------------------------------------
# The idea for this pass is to process:
#	EQU
#	Expansion of CALL
#	Macro definitions
#	Usage of EQU-defined constants in assembly-language operands
#	Expansion of macros
#	Conditionally-assembled code.
# The array expandedLines[] will end up being exactly the same length as lines[],
# and the entries will correspond 1-to-1, but will mostly be blank if the 
# preprocessor hasn't made any changes.  Except for macro expansions, the changed
# entries will be the same but with macro constants replaced by numeric literals.
# For macro expansions, the entry in the expandedLines[] array will itself be
# an array of lines comprising the expanded macro.  The errors[] array is also 
# in a similar 1-to-1 relationship, and contains error/warning messages for the lines.
expandedLines = []
errors = []
constants = {}
macros = {}
inMacro = ""
for n in range(0, len(lines)):
	line = lines[n]
	errors.append([])
	expandedLines.append("")
	# Split the line into fields.
	if line[:1] in [" ", "\t"] and not line.isspace():
		line = "@" + line
	fields = line.split()
	if len(fields) > 0 and fields[0] == "@":
        	fields[0] = ""
        	line = line[1:]
        	
	if inMacro != "":
		if len(fields) >= 2 and fields[1] == "ENDMAC":
			inMacro = ""
		else:
			macros[inMacro]["lines"].append(fields)
	elif len(fields) >= 3 and fields[0] != "" and fields[1] == "EQU":
		value,error = expression.yaEvaluate(fields[2], constants)
		if error != "":
			errors[n].append("Error: " + error)
		else:
			constants[fields[0]] = value 
	elif len(fields) >= 3 and fields[1] == "CALL":
		ofields = fields[2].split(",")
		if len(ofields) == 2:
			line1 = "%-7s%-8s%s" % (fields[0], "CLA", ofields[1])
			line2 = "%-7s%-8s%s" % ("", "HOP*", ofields[0])
			expandedLines[n] = [line1, line2]
		elif len(ofields) == 3:
			line1 = "%-7s%-8s%s" % (fields[0], "CLA", ofields[2])
			line2 = "%-7s%-8s%s" % ("", "STO", "775")
			line3 = "%-7s%-8s%s" % ("", "CLA", ofields[1])
			line4 = "%-7s%-8s%s" % ("", "HOP*", ofields[0])
			expandedLines[n] = [line1, line2, line3, line4]
	elif len(fields) >= 2 and fields[0] != "" and fields[1] == "MACRO":
		inMacro = fields[0]
		if len(fields) == 2:
			numArgs = 0
		else:
			numArgs = len(fields[2].split(","))
		macros[inMacro] = { "numArgs": numArgs, "lines": [] }
		
print("Constants:")		
for n in sorted(constants):
	print("\t" + n + "\t= " + str(constants[n]["number"]) + "B" + str(constants[n]["scale"]))
print("Macros:")
for n in sorted(macros):
	print("\t" + n + "\t= " + str(macros[n]))

sys.exit(1)

#----------------------------------------------------------------------------
#           TBD
#----------------------------------------------------------------------------
# Getting rid of blank lines,
# expanding the CALL macro, etc.  The object is basically to parse the whole
# mess into an easy-to-understand dictionary called inputFile. 
#
# As far as I know right now, it looks like we can painlessly assign a HOP constant
# to each line of input that needs one as well.  If not, then HOP assignment
# will have to be removed from this pass and one or more additional passes 
# added later to determine the HOPs.
inputFile = []
IM = 0
IS = 0
S = 1
LOC = 0
DM = 0
DS = 0
preConstants = {} # Numerical constants defined in the preprocessor.
for line in lines:
    inputLine = { "raw": line }
    
    # Split the line into fields.
    if line[:1] in [" ", "\t"] and not line.isspace():
        line = "@" + line
    fields = line.split()
    if len(fields) > 0 and fields[0] == "@":
        fields[0] = ""
    
    # Remove comments from the fields.
    for n in range(0, len(fields)):
        if fields[n][:1] == "#" or (n <= 1 and fields[n][:1] == "*"):
            if n == 1 and fields[0] == "":
                n = 0
            del fields[n:]
            break
    
    if len(fields) == 3:
        # Process preprocessor numerical constants.
        if fields[2][:1] == "(":
    	    efields = fields[2].split(")")
    	    if len(efields) != 2:
    	        inputLine["error"] = "Malformed preprocessor expression"
    	        inputFile.append(inputLine)
    	        continue
    	    expression = efields[0][1:]
    	    scale = efields[1]
    	    if scale == "":
    	        scale = "B0"
        #if fields[1] == "EQU":
        #	  TBD	
        # Operator/operand "CALL a,b" is really shorthand for 
        # "CLA b / HOP* a", so expand it in that manner.
        if fields[1] == "CALL":
            opfields = fields[2].split(",")
            if len(opfields) == 2:
                inputLine["macro"] = True
                inputFile.append(inputLine)
                inputLine = { 
                    "expanded": True, 
                    "raw": "\tCLA\t" + opfields[1],
                    "operator": "CLA",
                    "operand": opfields[1],
                    "hop": {"IM":IM, "IS":IS, "S":S, "LOC":LOC, "DM":DM, "DS":DS}
                }
                LOC += 1
                if fields[0] != "":
                    inputLine["lhs"] = fields[0]
                inputFile.append(inputLine)
                inputLine = { 
                    "expanded": True, 
                    "raw": "\tHOP*\t" + opfields[0],
                    "operator": "HOP*",
                    "operand": opfields[0],
                    "hop": {"IM":IM, "IS":IS, "S":S, "LOC":LOC, "DM":DM, "DS":DS}
                }
                LOC += 1
            else:
                inputLine["error"] = "Wrong number of arguments"
        # Okay, not a "CALL", so we can just handle "normal" input lines.
        elif fields[1] in operators:
            if fields[0] != "":
                inputLine["lhs"] = fields[0]
            inputLine["operator"] = fields[1]
            inputLine["operand"] = fields[2]
            inputLine["hop"] = {"IM":IM, "IS":IS, "S":S, "LOC":LOC, "DM":DM, "DS":DS}
            LOC += 1
        elif fields[1] in pseudos:
            if fields[0] != "":
                inputLine["lhs"] = fields[0]
            inputLine["pseudo"] = fields[1]
            inputLine["parameter"] = fields[2]
            if fields[1] == "CODE":
                opfields = fields[2].split("-")
                if len(opfields) == 4:
                    IM = int(opfields[0], 8)
                    IS = int(opfields[1], 8)
                    S = int(opfields[2], 8)
                    LOC = int(opfields[3], 8)
                else:
                    inputLine["error"] = "Wrong number of fields"
            elif fields[1] == "DATA":
                opfields = fields[2].split("-")
                if len(opfields) == 4:
                    DM = int(opfields[0], 8)
                    DS = int(opfields[1], 8)
                else:
                    inputLine["error"] = "Wrong number of fields"
            # All of the following pseudo-ops use up one word of memory.
            elif fields[1] in pseudos:
                inputLine["hop"] = {"IM":IM, "IS":IS, "S":S, "LOC":LOC, "DM":DM, "DS":DS}
                LOC += 1
        else:
            inputLine["error"] = "Unrecognized operator"
    elif len(fields) == 1:
        inputLine["lhs"] = fields[0]
        inputLine["hop"] = {"IM":IM, "IS":IS, "S":S, "LOC":LOC, "DM":DM, "DS":DS}
        LOC += 1
    elif len(fields) != 0:
        inputLine["error"] = "Wrong number of fields"
    inputFile.append(inputLine)

#----------------------------------------------------------------------------
# If it turns out later that the code above can't assign all HOPs in its
# single pass, insert code to do that here.  However, with my incomplete 
# state of knowledge right now, it doesn't seem as thought that will be
# necessary.

#----------------------------------------------------------------------------
#                           Create a symbol table
#----------------------------------------------------------------------------
# Create a table to quickly look up addresses of symbols.
symbols = {}
for inputLine in inputFile:
    if "lhs" in inputLine:
        if "hop" in inputLine:
            lhs = inputLine["lhs"]
            if lhs in symbols:
                if "error" in inputLine:
                    inputLine["error"] += ". " + "Symbol already defined"
                else:
                    inputLine["error"] = "Symbol already defined"
            symbols[lhs] = inputLine["hop"]
        else:
            if "error" in inputLine:
                inputLine["error"] += ". " + "Symbol without HOP."
            else:
                inputLine["error"] = "Symbol without HOP."

#----------------------------------------------------------------------------
#                           Complete the assembly
#----------------------------------------------------------------------------
# At this point we have a dictionary called inputFile in which the entire 
# input source file has been parsed into a relatively simple structure.  The
# addresses of all symbols (constants, variables, code) are known.  We should
# therefore be able to actually complete the entire assembly.
print("IM IS S LOC DM DS  A8-A1 A9 OP    CONSTANT    SOURCE STATEMENT")
for inputLine in inputFile:
    if "error" in inputLine:
        print("Error: " + inputLine["error"])
    
    if "hop" in inputLine:
        hop = inputLine["hop"]
        line = " %o %02o %o %03o  %o %02o  " % (hop["IM"], hop["IS"], hop["S"], 
                                                hop["LOC"], hop["DM"], 
                                                hop["DS"])
    else:
        line = "                  "
    
    if "operator" in inputLine:
        operator = inputLine["operator"]
        if operator == "SHR":
            n = 1
        elif operator == "SHL":
            n = 1
        elif operator == "SHF":
            n = 1
        elif operator == "EXM":
            n = 1
        else:
            n = 1
    
    print(line + "\t" + inputLine["raw"])

#----------------------------------------------------------------------------
#                           Print a symbol table
#----------------------------------------------------------------------------
print("\n\nSymbol Table:")
for key in sorted(symbols):
    hop = symbols[key]
    print(key + "\t" + " %o %02o %o %03o" % (hop["IM"], hop["IS"], hop["S"], 
                                                hop["LOC"]))
