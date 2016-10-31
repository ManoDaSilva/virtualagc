### FILE="Main.annotation"
# Copyright:	Public domain.
# Filename:	KALCMANU_STEERING.agc
# Purpose:	Part of the source code for Artemis (i.e., Colossus 3),
#		build 072.  This is for the Command Module's (CM) 
#		Apollo Guidance Computer (AGC), we believe for 
#		Apollo 15-17.
# Assembler:	yaYUL
# Contact:	Sergio Navarro <sergionavarrog@gmail.com>
# Website:	www.ibiblio.org/apollo/index.html
# Page Scans:	www.ibiblio.org/apollo/ScansForConversion/Artemis072/
# Mod history:	2009-08-19 SN	Adapted from corresponding Comanche 055 file.
# 		2009-09-04 JL	Fix typos.
# 		2010-01-31 JL	Fixed build errors.
#		2010-02-20 RSB	Un-##'d this header.

## Page 418

# GENERATION OF STEERING COMMANDS FOR DIGITAL AUTOPILOT FREE FALL MANEUVERS
#
# NEW COMMANDS WILL BE GENERATED EVERY ONE SECOND DURING THE MANEUVER

		SETLOC	KALCMON1
		BANK
		
		EBANK=	BCDU
		
		COUNT*	$$/KALC
NEWDELHI	CAF	R67BIT
		MASK	FLAGWRD8
		EXTEND
		BZF	NEWANGL -3	# NON-R67 SEQUENCE

		CAF	TRACKBIT
		MASK	FLAGWRD1
		EXTEND			# CHECK TRACKFLAG
		BZF	MYSTEND		# IF OFF DO MYSTEND

 -3		CS	HOLDFLAG
		EXTEND			# CHECK HOLDFLAG
		BZMF	NOGOM2		# IF POS, DO STOPRATE

NEWANGL		TC	INTPRET
 +1		AXC,1	AXC,2
			MIS		# COMPUTE THE NEW MATRIX FROM S/C TO
			DEL		# STABLE MEMBER AXES
		CALL
			MXM3
		VLOAD	STADR
		STOVL	MIS +12D	# CALCULATE NEW DESIRED CDU ANGLES
		STADR
		STOVL	MIS +6D
		STADR
		STORE	MIS
		AXC,1	CALL
			MIS
			DCMTOCDU	# PICK UP THE NEW CDU ANGLES FROM MATRIX
		RTB	
			V1STO2S
NWNGL17D	STORE	NCDU		# NEW CDU ANGLES (TAG IS USED BY EDIT)
		BONCLR	EXIT
			CALCMAN2
			MANUSTAT	# TO START MANEUVER
 -1		CAF	TWO		# 	   +0 OTHERWISE
INCRDCDU	TS	KSPNDX
		DOUBLE
		TS	KDPNDX
		INDEX	KSPNDX
## Page 419
		CA	NCDU		# NEW DESIRED CDU ANGLES
		EXTEND
		INDEX	KSPNDX
		MSU	BCDU		# INITIAL S/C ANGLE OR PREVIOUS DESIRED
		EXTEND			# CDU ANGLES
		MP	QUADROT
		INDEX	KDPNDX
		DXCH	DELCDUX		# ANGEL INCREMENTS TO BE ADDED TO
		INDEX	KSPNDX		# DCDU EVERY TENTH SEC
		CA	NCDU		# BY LEM DAP
		INDEX	KSPNDX
		XCH	BCDU
		INDEX	KDPNDX
		TS	CDUXD
		CCS	KSPNDX
		TCF	INCRDCDU	# LOOP FOR THREE AXES
		
		RELINT		

# COMPARE PRESENT TIME WITH TIME TO TERMINATE MANEUVER

TMANUCHK	TC	TIMECHK
		TC	POSTJUMP
		CADR	CONTMANU
		
		CAF	ONE		
MANUSTAL	TC	WAITLIST
		EBANK=	BCDU
		2CADR	MANUSTOP
		
		TCF	ENDOFJOB
		
		
TIMECHK		EXTEND
		DCS	TIME2
		DXCH	TTEMP
		EXTEND
		DCA	TM
		DAS	TTEMP
		CCS	TTEMP
		TC	Q
		TCF	+2
		TCF	2NDRETRN
		CCS	TTEMP +1
		TC	Q
		TCF	MANUOFF
		COM
MANUOFF		AD	1SEC
		EXTEND
		BZMF	2NDRETRN
		INCR	Q
## Page 420
2NDRETRN	INCR	Q
		TCF	Q+1
MYSTEND		TC	POSTJUMP
		CADR	FIXDB

		SETLOC	MANUSTUF
		BANK

		COUNT*	$$/KALC
MANUSTAT	EXIT			# INITIALIZATION ROUTINE FOR AUTO
		CAF	R67BIT		#                     MANEUVERS
		MASK	FLAGWRD8
		EXTEND
		BZF	+5
		EXTEND			# R67 RUNNING
		DCA	DPOSMAX
		DXCH	TM
		TCF	TMDON
		EXTEND			# NON-R67 PROGRAM
		DCA	TIME2
		DAS	TM		# TM+T0    MANEUVER COMPLETION TIME
		CS	1SEC
		TS	L
		CS	ZERO
		DAS	TM		# (TM+T0)-1
TMDON		INHINT
		CS	ONE		# ENABLE AUTOPILOT TO PERFORM
		TS	HOLDFLAG	# AUTOMATIC MANEUVERS
		CS	RATEINDX	# SEE IF MANEUVERING AT HIGH RATE
		AD	SIX
		EXTEND
		BZMF	HIGHGAIN
		TCF	+4
HIGHGAIN	CS	RCSFLAGS	# IF SO, SET HIGH RATE FLAG (BIT 15 OF
		MASK	BIT15		# RCSFLAGS)
		ADS	RCSFLAGS
		EXTEND
		DCA	BRATE		# X-AXIS MANEUVER RATE
		DXCH	WBODY
		EXTEND
		DCA	BRATE +2	# Y-AXIS MANEUVER RATE
		DXCH	WBODY1
		EXTEND
		DCA	BRATE +4	# Z-AXIS MANEUVER RATE
		DXCH	WBODY2
		CA	BIASTEMP +1	# INSERT ATTITUDE ERROR BIASES
		TS	BIAS		# INTO AUTOPILOT
		CA	BIASTEMP +3
		TS	BIAS1
		CA	BIASTEMP +5
## Page 421
		TS	BIAS2
		CA	TIME1
		AD	1SEC
		XCH	NEXTIME
		TC	POSTJUMP
		CADR	INCRDCDU -1
				
CONTMANU	INHINT			# CONTINUE WITH UPDATE PROCESS
		CS	TIME1		
		AD	NEXTIME
		CCS	A
		AD	ONE
		TCF	MANUCALL
		AD	NEGMAX
		COM
MANUCALL	TC	TWIDDLE
		ADRES	UPDTCALL
		RELINT
		CAF	1SEC		# INCREMENT TIME FOR NEXT UPDATE
		ADS	NEXTIME
		TCF	ENDOFJOB

UPDTCALL	CAF	R67BIT
		MASK	FLAGWRD8
		EXTEND
		BZF	+5

		CCS	R61CNTR
		TCF	+2
		TCF	DOREMIS
		TS	R61CNTR

		CAF	PRIO26
		TC	FINDVAC		# OF STEERING COMMANDS
		EBANK=	BCDU
		2CADR	NEWDELHI

		TC	TASKOVER

DOREMIS		CAF	PRIO26
		TC	FINDVAC
		EBANK=	BCDU
		2CADR	R67RSTRT	# MAKE SURE MIS DOES DEGRADE

		TC	TASKOVER
		
## Page 422
# ROUTINE FOR TERMINATING AUTOMATIC MANEUVERS

		SETLOC	KALCMON3
		BANK
	
		COUNT*	$$/KALC
MANUSTOP	TC	STOPYZ
		TC	IBNKCALL
		CADR	LOADYZ

ENDROLL		CA	CPHI
		TS	CDUXD		# SET CDUXD TO THE COMMANDED OUTER GIMBAL
		TC	STOPRATE
ENDMANU		CAF	PRIO14
		TC	FINDVAC
		EBANK=	R61CNTR
		2CADR	ENDMANUV
		
		TC	TASKOVER
		
		SETLOC	STOPRAT
		BANK
		COUNT*	$$/KALC
STOPRATE	CAF	ZERO
		TS	DELCDUX
		TS	DELCDUX	+1	# ZERO ROLL INCREMENTAL ANGLES
		TS	WBODY		# RATE
		TS	WBODY +1
		TS	BIAS		# BIAS
		
		CS	BIT15		# MAKE SURE HIGH RATE FLAG (BIT 15 OF
		MASK	RCSFLAGS	# RCSFLAGS) IS RESET.
		TS	RCSFLAGS
		
STOPYZ		CAF	ZERO
		TS	DELCDUY		# ZERO PITCH, YAW
		TS	DELCDUY	+1	# INCREMENTAL ANGLES
		TS	DELCDUZ
		TS	DELCDUZ	+1
		TS	WBODY1		# RATES
		TS	WBODY1 +1
		TS	WBODY2
		TS	WBODY2 +1
		TS	BIAS1		# BIASES
		TS	BIAS2
		TC	Q
		
		SETLOC MANUSTUF
		BANK

## Page 423
		COUNT*	$$/KALC
ZEROEROR	CA	CDUX		# PICK UP CDU ANGLES AND STORE IN
		TS	CDUXD		# CDU DESIRED
		CA	CDUY
		TS	CDUYD
		CA	CDUZ
		TS	CDUZD
		TC	Q

		SETLOC	KALCMON1
		BANK

		COUNT*	$$/KALC		
LOADCDUD	CA	CPHI		# STORE TERMINAL ANGLES INTO
		TS	CDUXD		# COMMAND ANGLES
LOADYZ		CA	CTHETA
		TS	CDUYD
		CA	CPSI
		TS	CDUZD
		TC	Q