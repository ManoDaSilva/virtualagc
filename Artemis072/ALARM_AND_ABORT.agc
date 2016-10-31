### FILE="Main.annotation"
# Copyright:	Public domain.
# Filename:	ALARM_AND_ABORT.agc
# Purpose:	Part of the source code for Artemis (i.e., Colossus 3),
#		build 072.  This is for the Command Module's (CM)
#		Apollo Guidance Computer (AGC), we believe for
#		Apollo 15-17.
# Assembler:	yaYUL
# Contact:	Jim Lawton <jim DOT lawton AT gmail DOT com>
# Website:	www.ibiblio.org/apollo/index.html
# Page Scans:	www.ibiblio.org/apollo/ScansForConversion/Artemis072/
# Mod history:	2009-08-18 JL	Adapted from corresponding Comanche 055 file.
#		2010-02-10 JL	Fixed error on p1488.
#		2010-02-20 RSB	Un-##'d this header.

## Page 1486

# THE FOLLOWING SUBROUTINE MAY BE CALLED TO DISPLAY A NON-ABORTIVE ALARM CONDITION. IT MAY BE CALLED
# EITHER IN INTERRUPT OR UNDER EXECUTIVE CONTROL.
#
# 	CALLING SEQUENCE IS AS FOLLOWS:
#
#	TC	ALARM
#	OCT	NNNNN
#				(RETURNS HERE)

		SETLOC	FFTAG7
		BANK

		EBANK=	FAILREG

		COUNT*	$$/ALARM

# ALARM TURNS ON THE PROGRAM ALARM LIGHT, BUT DOES NOT DISPLAY.

ALARM		INHINT

		CA	Q
ALARM2		TS	ALMCADR
		INDEX	Q
		CA	0
BORTENT		TS	L

PRIOENT		CA	BBANK
 +1		EXTEND
		ROR	SUPERBNK	# ADD SUPER BITS.
		TS	ALMCADR +1

LARMENT		CA	Q		# STORE RETURN FOR ALARM
		TS	ITEMP1

CHKFAIL1	CCS	FAILREG		# IS ANYTHING IN FAILREG
		TCF	CHKFAIL2	# YES TRY NEXT REG
		CA	L
		TS	FAILREG
		TCF	PROGLARM	# TURN ALARM LIGHT ON FOR FIRST ALARM

CHKFAIL2	CCS	FAILREG +1
		TCF	PROGLARM
		CA	L
		TS	FAILREG +1
		
PROGLARM	LXCH	FAILREG +2	# STORE AS "MOST RECENT" ALARM CODE

		CS	DSPTAB +11D	# TURN ON PROGRAM ALARM IF OFF
		MASK	BIT15+9
		ADS	DSPTAB +11D

MULTEXIT	XCH	ITEMP1		# OBTAIN RETURN ADDRESS IN A
## Page 1487
		RELINT
		INDEX	A
		TC	1

# PRIOLARM DISPLAYS V05N09 VIA PRIODSPR WITH 3 RETURNS TO THE USER FROM THE ASTRONAUT AT CALL LOC +1,+2,+3 AND
# AN IMMEDIATE RETURN TO THE USER AT CALL LOC +4. EXAMPLE FOLLOWS,
#		CAF	OCTXX		# ALARM CODE
#		TC	BANKCALL
#		CADR	PRIOLARM
#
#		...	...
#		...	...
#		...	...		# ASTRONAUT RETURN
#		TC	PHASCHNG	# IMMEDIATE RETURN TO USER. RESTART
#		OCT	X.1		# PHASE CHANGE FOR PRIO DISPLAY

		SETLOC	DISPLAYS
		BANK

		COUNT*	$$/DSPLA
PRIOLARM	INHINT			# * * * KEEP IN DISPLAY ROUTINES BANK
		TS	L		# SAVE ALARM CODE

		CA	BUF2		# 2 CADR OF PRIOLARM USER
		TS	ALMCADR
		CA	BUF2 +1
		TC	PRIOENT +1	# * LEAVE L ALONE
-2SEC		DEC	-200		# *** DONT MOVE
		CAF	V05N09
		TCF	PRIODSPR
		
		SETLOC	FFTAG13
		BANK

		COUNT*	$$/ALARM
BAILOUT		INHINT
		CA	Q
		TS	ALMCADR
		
		TC	BANKCALL
		CADR	VAC5STOR
		
		INDEX	ALMCADR
		CAF	0
		TC	BORTENT
BIT15+9		OCT	40400

 -1		INHINT
WHIMPER		CA	TWO
		AD	Z
## Page 1488
		TS	BRUPT
		RESUME
		TC	POSTJUMP	# RESUME SENDS CONTROL HERE
		CADR	ENEMA
		
		SETLOC	FFTAG7
		COUNT*	$$/ALARM
		BANK
		
POODOO		INHINT
		CA	Q
		TS	ALMCADR

		TC	BANKCALL
		CADR	VAC5STOR	# STORE ERASABLES FOR DEBUGGING PURPOSES.
		
		INDEX	ALMCADR
		CAF	0
ABORT2		TC	BORTENT

OCT77770	OCT	77770		# DONT MOVE
		CA	V37FLBIT	# IS AVERAGE G ON
		MASK	FLAGWRD7
		CCS	A
		TC	WHIMPER -1	# YES.  DONT DO POODOO.  DO BAILOUT.

		CS	BIT14		# DISREGARD ENTRY SETTING
		MASK	EXTVBACT	# EXTENDED VBS ACTIVITY?
		CCS	A
		TCF	WHIMPER -1	# YES.  DONT DO POODOO.  DO BAILOUT.

		TC	DOWNFLAG
		ADRES	STATEFLG
		
		TC	DOWNFLAG
		ADRES	AUTOSEQ
		
		TC	DOWNFLAG
		ADRES	REINTFLG
		
		TC	DOWNFLAG
		ADRES	UTFLAG
		TC	DOWNFLAG
		ADRES	RNDVZFLG
		TC	DOWNFLAG
		ADRES	TRACKFLG	# FORCE STOPRATE
		TC	DOWNFLAG
		ADRES	NODOFLAG
		
		TC	BANKCALL
## Page 1489
		CADR	MR.KLEAN
		TC	WHIMPER
		
DOALARM		EQUALS	ENDOFJOB

# CALLING SEQUENCE FOR VARALARM
#		CAF	(ALARM)
#		TC	VARALARM

# VARALARM TURNS ON PROGRAM ALARM LIGHT BUT DOES NOT DISPLAY

VARALARM	INHINT

		TS	L		# SAVE USERS ALARM CODE

		CA	Q		# SAVE USERS Q
		TS	ALMCADR

		TC	PRIOENT
OCT14		OCT	14		# DONT MOVE

		TC	ALMCADR		# RETURN TO USER

ABORT		EQUALS	BAILOUT		# *** TEMPORARY UNTIL ABORT CALLS OUT