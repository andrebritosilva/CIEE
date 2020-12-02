#Include 'Protheus.ch'
#Include 'birtdataset.ch'
#INCLUDE "tbiconn.ch"
#INCLUDE "topconn.ch"
#DEFINE ENTER chr(13)+chr(10)
/*==================================================================================================
  DataSet para Relatorio de Ressarcimento por agrupamento
  MIT044 - 
@author     D.Hirabara
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//==================================================================================================
//	Data Set para relatório CGPER014.PRW
//==================================================================================================*/
USER_DATASET CGPE21

TITLE "Relatório de Ressarcimento" 
DESCRIPTION  "Relatório de Ressarcimento"

COLUMNS   
	DEFINE COLUMN C_CODCONV		TYPE CHARACTER 	SIZE 4 		LABEL "C_CODCONV"
	DEFINE COLUMN C_CCDESC		TYPE CHARACTER 	SIZE 100	LABEL "C_CCDESC" 
	DEFINE COLUMN C_CCDESCRD	TYPE CHARACTER 	SIZE 47 	LABEL "C_CCDESCRD" 
	DEFINE COLUMN C_CODLOCA		TYPE CHARACTER 	SIZE 4 		LABEL "C_CODLOCA"
	DEFINE COLUMN C_DESCLOC		TYPE CHARACTER 	SIZE 45		LABEL "C_DESCLOC" 
	DEFINE COLUMN C_MAT 		TYPE CHARACTER 	SIZE 6 		LABEL "C_MAT"
	DEFINE COLUMN C_NOME		TYPE CHARACTER 	SIZE 30 	LABEL "C_NOME"
	DEFINE COLUMN C_ADMISS		TYPE CHARACTER 	SIZE 10 	LABEL "C_ADMISS"
	DEFINE COLUMN C_DEMISS		TYPE CHARACTER 	SIZE 10 	LABEL "C_DEMISS"
	
	DEFINE COLUMN C_TELELOC		TYPE CHARACTER 	SIZE 20		LABEL "C_TELELOC" 
	DEFINE COLUMN C_CNPJLOC		TYPE CHARACTER 	SIZE 18		LABEL "C_CNPJLOC" 
	DEFINE COLUMN C_ENDELOC		TYPE CHARACTER 	SIZE 80		LABEL "C_ENDELOC" 
	DEFINE COLUMN C_MAILLOC		TYPE CHARACTER 	SIZE 70		LABEL "C_MAILLOC" 
	
	DEFINE COLUMN C_SETOR		TYPE CHARACTER 	SIZE 8		LABEL "C_SETOR" 
	DEFINE COLUMN C_SETORDSC	TYPE CHARACTER 	SIZE 45		LABEL "C_SETORDSC" 
	
	DEFINE COLUMN C_MESANO		TYPE CHARACTER 	SIZE 6		LABEL "C_MESANO" 
	
	DEFINE COLUMN C_COL1		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL1"
	DEFINE COLUMN C_COL2		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL2"
	DEFINE COLUMN C_COL3		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL3"
	DEFINE COLUMN C_COL4		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL4"
	DEFINE COLUMN C_COL5		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL5"
	DEFINE COLUMN C_COL6		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL6"
	DEFINE COLUMN C_COL7		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL7"
	DEFINE COLUMN C_COL8		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL8"
	DEFINE COLUMN C_COL9		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL9"
	DEFINE COLUMN C_COL10		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL10"
	DEFINE COLUMN C_COL11		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL11"
	DEFINE COLUMN C_COL12		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL12"
	DEFINE COLUMN C_COL13		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL13"
	DEFINE COLUMN C_COL14		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL14"
	DEFINE COLUMN C_COL15		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL15"
	DEFINE COLUMN C_COL16		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL16"
	DEFINE COLUMN C_COL17		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL17"
	DEFINE COLUMN C_COL18		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL18"
	DEFINE COLUMN C_COL19		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL19"
	DEFINE COLUMN C_COL20		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL20"
	DEFINE COLUMN C_COL21		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL21"
	DEFINE COLUMN C_COL22		TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_COL22"
	DEFINE COLUMN C_TOT			TYPE NUMERIC 	SIZE 12		DECIMALS 	2 	LABEL "C_TOT"

	DEFINE COLUMN C_CAB1		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB1"
	DEFINE COLUMN C_CAB2		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB2"
	DEFINE COLUMN C_CAB3		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB3"
	DEFINE COLUMN C_CAB4		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB4"
	DEFINE COLUMN C_CAB5		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB5"
	DEFINE COLUMN C_CAB6		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB6"
	DEFINE COLUMN C_CAB7		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB7"
	DEFINE COLUMN C_CAB8		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB8"
	DEFINE COLUMN C_CAB9		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB9"
	DEFINE COLUMN C_CAB10		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB10"
	DEFINE COLUMN C_CAB11		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB11"
	DEFINE COLUMN C_CAB12		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB12"
	DEFINE COLUMN C_CAB13		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB13"
	DEFINE COLUMN C_CAB14		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB14"
	DEFINE COLUMN C_CAB15		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB15"
	DEFINE COLUMN C_CAB16		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB16"
	DEFINE COLUMN C_CAB17		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB17"
	DEFINE COLUMN C_CAB18		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB18"
	DEFINE COLUMN C_CAB19		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB19"
	DEFINE COLUMN C_CAB20		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB20"
	DEFINE COLUMN C_CAB21		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB21"
	DEFINE COLUMN C_CAB22		TYPE CHARACTER 	SIZE 45	LABEL "C_CAB22"
	
	DEFINE COLUMN C_SUMTP		TYPE NUMERIC 	SIZE 1 	LABEL "C_SUMTP"
	DEFINE COLUMN C_TCONT		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCONT"
	DEFINE COLUMN C_TCOL1		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL1"
	DEFINE COLUMN C_TCOL2		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL2"
	DEFINE COLUMN C_TCOL3		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL3"
	DEFINE COLUMN C_TCOL4		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL4"
	DEFINE COLUMN C_TCOL5		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL5"
	DEFINE COLUMN C_TCOL6		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL6"
	DEFINE COLUMN C_TCOL7		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL7"
	DEFINE COLUMN C_TCOL8		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL8"
	DEFINE COLUMN C_TCOL9		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL9"
	DEFINE COLUMN C_TCOL10		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL10"
	DEFINE COLUMN C_TCOL11		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL11"
	DEFINE COLUMN C_TCOL12		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL12"
	DEFINE COLUMN C_TCOL13		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL13"
	DEFINE COLUMN C_TCOL14		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL14"
	DEFINE COLUMN C_TCOL15		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL15"
	DEFINE COLUMN C_TCOL16		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL16"
	DEFINE COLUMN C_TCOL17		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL17"
	DEFINE COLUMN C_TCOL18		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL18"
	DEFINE COLUMN C_TCOL19		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL19"
	DEFINE COLUMN C_TCOL20		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL20"
	DEFINE COLUMN C_TCOL21		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL21"
	DEFINE COLUMN C_TCOL22		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TCOL22"
	DEFINE COLUMN C_TGERAL		TYPE NUMERIC 	SIZE 12	DECIMALS 2 	LABEL "C_TGERAL"

	DEFINE COLUMN C_DESCON		TYPE NUMERIC 	SIZE 14		DECIMALS 	2 	LABEL "C_DESCON"
	DEFINE COLUMN C_ACRESC		TYPE NUMERIC 	SIZE 14		DECIMALS 	2 	LABEL "C_ACRESC"
	DEFINE COLUMN C_TXTDES		TYPE CHARACTER 	SIZE 200	LABEL "C_TXTDES" 
	DEFINE COLUMN C_TXTACR		TYPE CHARACTER 	SIZE 200	LABEL "C_TXTACR" 
	
	
DEFINE QUERY 	"SELECT * FROM " + cWTabAlias
PROCESS DATASET

	// ===========
	//Local cWTabAlias 	
	Local cQuery		:= ""
	Local _aArea        := GetArea()      
	
	Private aCampos := {}

	If self:isPreview()
	EndIf	

	aAdd ( aCampos, {"C_CODCONV" ,"C", 4,0} )
	aAdd ( aCampos, {"C_CCDESC"  ,"C",100,0} )
	aAdd ( aCampos, {"C_CCDESCRD","C",47,0} )
	aAdd ( aCampos, {"C_CODLOCA" ,"C", 4,0} )
	aAdd ( aCampos, {"C_DESCLOC" ,"C",45,0} )
	aAdd ( aCampos, {"C_MAT"     ,"C", 6,0} )
	aAdd ( aCampos, {"C_NOME"    ,"C",30,0} )
	aAdd ( aCampos, {"C_ADMISS"  ,"C",10,0} )
	aAdd ( aCampos, {"C_DEMISS"  ,"C",10,0} )
	aAdd ( aCampos, {"C_TELELOC" ,"C",20,0} )
	aAdd ( aCampos, {"C_CNPJLOC" ,"C",18,0} )
	aAdd ( aCampos, {"C_ENDELOC" ,"C",80,0} )
	aAdd ( aCampos, {"C_MAILLOC" ,"C",70,0} )
	aAdd ( aCampos, {"C_SETOR"   ,"C", 8,0} )
	aAdd ( aCampos, {"C_SETORDSC","C",45,0} )
	aAdd ( aCampos, {"C_MESANO"  ,"C", 6,0} )
	aAdd ( aCampos, {"C_COL1"    ,"N",12,2} )
	aAdd ( aCampos, {"C_COL2"    ,"N",12,2} )
	aAdd ( aCampos, {"C_COL3"    ,"N",12,2} )
	aAdd ( aCampos, {"C_COL4"    ,"N",12,2} )
	aAdd ( aCampos, {"C_COL5"    ,"N",12,2} )
	aAdd ( aCampos, {"C_COL6"    ,"N",12,2} )
	aAdd ( aCampos, {"C_COL7"    ,"N",12,2} )
	aAdd ( aCampos, {"C_COL8"    ,"N",12,2} )
	aAdd ( aCampos, {"C_COL9"    ,"N",12,2} )
	aAdd ( aCampos, {"C_COL10"   ,"N",12,2} )
	aAdd ( aCampos, {"C_COL11"   ,"N",12,2} )
	aAdd ( aCampos, {"C_COL12"   ,"N",12,2} )
	aAdd ( aCampos, {"C_COL13"   ,"N",12,2} )
	aAdd ( aCampos, {"C_COL14"   ,"N",12,2} )
	aAdd ( aCampos, {"C_COL15"   ,"N",12,2} )
	aAdd ( aCampos, {"C_COL16"   ,"N",12,2} )
	aAdd ( aCampos, {"C_COL17"   ,"N",12,2} )
	aAdd ( aCampos, {"C_COL18"   ,"N",12,2} )
	aAdd ( aCampos, {"C_COL19"   ,"N",12,2} )
	aAdd ( aCampos, {"C_COL20"   ,"N",12,2} )
	aAdd ( aCampos, {"C_COL21"   ,"N",12,2} )
	aAdd ( aCampos, {"C_COL22"   ,"N",12,2} )
	aAdd ( aCampos, {"C_TOT"     ,"N",12,2} )
	aAdd ( aCampos, {"C_CAB1"    ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB2"    ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB3"    ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB4"    ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB5"    ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB6"    ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB7"    ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB8"    ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB9"    ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB10"   ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB11"   ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB12"   ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB13"   ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB14"   ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB15"   ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB16"   ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB17"   ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB18"   ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB19"   ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB20"   ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB21"   ,"C",45,0} )
	aAdd ( aCampos, {"C_CAB22"   ,"C",45,0} )
	aAdd ( aCampos, {"C_SUMTP"   ,"N", 1,0} )
	aAdd ( aCampos, {"C_TCONT"   ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL1"   ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL2"   ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL3"   ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL4"   ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL5"   ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL6"   ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL7"   ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL8"   ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL9"   ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL10"  ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL11"  ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL12"  ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL13"  ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL14"  ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL15"  ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL16"  ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL17"  ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL18"  ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL19"  ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL20"  ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL21"  ,"N",12,2} )
	aAdd ( aCampos, {"C_TCOL22"  ,"N",12,2} )
	aAdd ( aCampos, {"C_TGERAL"  ,"N",12,2} )
	aAdd ( aCampos, {"C_DESCON"  ,"N",14,2} )
	aAdd ( aCampos, {"C_ACRESC"  ,"N",14,2} )
	aAdd ( aCampos, {"C_TXTDES"  ,"C",200,0} )
	aAdd ( aCampos, {"C_TXTACR"  ,"C",200,0} )

	If SELECT(cWTabAlias) > 0
		(cWTabAlias)->( dbclosearea() )
	Endif
	tcDelFile(cWTabAlias)
	dbCreate(cWTabAlias, aCampos, "TOPCONN")
	dbUseArea(.t., "TOPCONN", cWTabAlias, cWTabAlias, .T., .F.)

	cursorwait()
	cursorarrow()
    
	If lAgrupa              

		Processa({|lEnd| fAgruImpr(cPerg,cWTabAlias)	},If(_TpArqSaida==3,"Gerando XLSs...","Gerando PDFs..."))
                                                    
	Else        
		
		Processa({|lEnd| fResImpr(cWTabAlias)	},If(_TpArqSaida==3,"Gerando XLSs...","Gerando PDFs..."))
	
	Endif
	
	(cWTabAlias)->(dbgotop())
	nTotApr  := 0
	nTotConv := 0
	nTotAcres:= 0
	nTotDesc := 0
	nTotGeral:= 0
	aTotCols := {(cWTabAlias)->C_CODCONV,{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}}
	WHILE (cWTabAlias)->(!Eof())
		
		IF aTotCols[1] != (cWTabAlias)->C_CODCONV
			nTotConv++
			(cWTabAlias)->(dbskip(-1))
			RecLock( cWTabAlias, .F. )
			( cWTabAlias )->C_SUMTP	:= 1
			( cWTabAlias )->C_TCONT	:= nTotApr
			( cWTabAlias )->C_TCOL1 := aTotCols[2][1]
			( cWTabAlias )->C_TCOL2 := aTotCols[2][2]
			( cWTabAlias )->C_TCOL3 := aTotCols[2][3]
			( cWTabAlias )->C_TCOL4 := aTotCols[2][4]
			( cWTabAlias )->C_TCOL5 := aTotCols[2][5]
			( cWTabAlias )->C_TCOL6 := aTotCols[2][6]
			( cWTabAlias )->C_TCOL7 := aTotCols[2][7]
			( cWTabAlias )->C_TCOL8 := aTotCols[2][8]
			( cWTabAlias )->C_TCOL9 := aTotCols[2][9]
			( cWTabAlias )->C_TCOL10:= aTotCols[2][10]
			( cWTabAlias )->C_TCOL11:= aTotCols[2][11]
			( cWTabAlias )->C_TCOL12:= aTotCols[2][12]
			( cWTabAlias )->C_TCOL13:= aTotCols[2][13]
			( cWTabAlias )->C_TCOL14:= aTotCols[2][14]
			( cWTabAlias )->C_TCOL15:= aTotCols[2][15]
			( cWTabAlias )->C_TCOL16:= aTotCols[2][16]
			( cWTabAlias )->C_TCOL17:= aTotCols[2][17]
			( cWTabAlias )->C_TCOL18:= aTotCols[2][18]
			( cWTabAlias )->C_TCOL19:= aTotCols[2][19]
			( cWTabAlias )->C_TCOL20:= aTotCols[2][20]
			( cWTabAlias )->C_TCOL21:= aTotCols[2][21]
			( cWTabAlias )->C_TCOL22:= aTotCols[2][22]
			( cWTabAlias )->( MsUnlock() )		
			(cWTabAlias)->(dbskip())
			nTotApr:= 0
			aTotCols:= {(cWTabAlias)->C_CODCONV,{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}}	
		ENDIF
		
		aTotCols[2][1]+= ( cWTabAlias )->C_COL1
		aTotCols[2][2]+= ( cWTabAlias )->C_COL2
		aTotCols[2][3]+= ( cWTabAlias )->C_COL3
		aTotCols[2][4]+= ( cWTabAlias )->C_COL4
		aTotCols[2][5]+= ( cWTabAlias )->C_COL5
		aTotCols[2][6]+= ( cWTabAlias )->C_COL6
		aTotCols[2][7]+= ( cWTabAlias )->C_COL7
		aTotCols[2][8]+= ( cWTabAlias )->C_COL8
		aTotCols[2][9]+= ( cWTabAlias )->C_COL9
		aTotCols[2][10]+= ( cWTabAlias )->C_COL10
		aTotCols[2][11]+= ( cWTabAlias )->C_COL11
		aTotCols[2][12]+= ( cWTabAlias )->C_COL12
		aTotCols[2][13]+= ( cWTabAlias )->C_COL13
		aTotCols[2][14]+= ( cWTabAlias )->C_COL14
		aTotCols[2][15]+= ( cWTabAlias )->C_COL15
		aTotCols[2][16]+= ( cWTabAlias )->C_COL16
		aTotCols[2][17]+= ( cWTabAlias )->C_COL17
		aTotCols[2][18]+= ( cWTabAlias )->C_COL18
		aTotCols[2][19]+= ( cWTabAlias )->C_COL19
		aTotCols[2][20]+= ( cWTabAlias )->C_COL20
		aTotCols[2][21]+= ( cWTabAlias )->C_COL21
		aTotCols[2][22]+= ( cWTabAlias )->C_COL22

		nTotGeral+= ( cWTabAlias )->C_TOT
		
		nTotApr++
	(cWTabAlias)->(dbskip())
	END 
	
	IF nTotApr > 0
		nTotConv++
		(cWTabAlias)->(dbskip(-1))
		RecLock( cWTabAlias, .F. )
		( cWTabAlias )->C_SUMTP	:= 1
		( cWTabAlias )->C_TCONT	:= nTotApr
		( cWTabAlias )->C_TCOL1 := aTotCols[2][1]
		( cWTabAlias )->C_TCOL2 := aTotCols[2][2]
		( cWTabAlias )->C_TCOL3 := aTotCols[2][3]
		( cWTabAlias )->C_TCOL4 := aTotCols[2][4]
		( cWTabAlias )->C_TCOL5 := aTotCols[2][5]
		( cWTabAlias )->C_TCOL6 := aTotCols[2][6]
		( cWTabAlias )->C_TCOL7 := aTotCols[2][7]
		( cWTabAlias )->C_TCOL8 := aTotCols[2][8]
		( cWTabAlias )->C_TCOL9 := aTotCols[2][9]
		( cWTabAlias )->C_TCOL10:= aTotCols[2][10]
		( cWTabAlias )->C_TCOL11:= aTotCols[2][11]
		( cWTabAlias )->C_TCOL12:= aTotCols[2][12]
		( cWTabAlias )->C_TCOL13:= aTotCols[2][13]
		( cWTabAlias )->C_TCOL14:= aTotCols[2][14]
		( cWTabAlias )->C_TCOL15:= aTotCols[2][15]
		( cWTabAlias )->C_TCOL16:= aTotCols[2][16]
		( cWTabAlias )->C_TCOL17:= aTotCols[2][17]
		( cWTabAlias )->C_TCOL18:= aTotCols[2][18]
		( cWTabAlias )->C_TCOL19:= aTotCols[2][19]
		( cWTabAlias )->C_TCOL20:= aTotCols[2][20]
		( cWTabAlias )->C_TCOL21:= aTotCols[2][21]
		( cWTabAlias )->C_TCOL22:= aTotCols[2][22]
		( cWTabAlias )->C_TGERAL:= (nTotGeral + (( cWTabAlias )->C_ACRESC * nTotConv)) - (( cWTabAlias )->C_DESCON * nTotConv)
		// Parâmetro de Desconto/Acrescimo
		( cWTabAlias )->C_DESCON:= nDescon
		( cWTabAlias )->C_ACRESC:= nAcresc
		( cWTabAlias )->C_TXTDES:= cTxtDeb
		( cWTabAlias )->C_TXTACR:= cTxtCre
		
		( cWTabAlias )->( MsUnlock() )
	ENDIF

// Grava array e chama rotina para replicar dados no BackOffice
	aBkpDds := {}
	(cWTabAlias)->(dbgotop())
	While (cWTabAlias)->(!Eof())
		// reseta variaveis
		aDados := {}
		aAdd(aDados,(cWTabAlias)->C_CODCONV + " - " + (cWTabAlias)->C_CCDESC)
		aAdd(aDados,(cWTabAlias)->C_CODCONV + " - " + (cWTabAlias)->C_DESCLOC)
		aAdd(aDados,(cWTabAlias)->C_CNPJLOC)
		aAdd(aDados,(cWTabAlias)->C_ENDELOC)
		aAdd(aDados,(cWTabAlias)->C_TELELOC)
		aAdd(aDados,(cWTabAlias)->C_MAILLOC)
		aAdd(aDados,"")
		aAdd(aDados,"")
		aAdd(aDados,"")
		aAdd(aDados,"")
		aAdd(aDados,"")
		aAdd(aDados,(cWTabAlias)->C_MAT)
		aAdd(aDados,(cWTabAlias)->C_NOME)
		aAdd(aDados,(cWTabAlias)->C_ADMISS)
		aAdd(aDados,(cWTabAlias)->C_DEMISS)
		aAdd(aDados,"")
		aAdd(aDados,0)
		aAdd(aDados,0)
		aAdd(aDados,"")
		aAdd(aDados,"")
		// clona dados do array
		aAdd(aBkpDds,aClone(aDados))
		// executa proxima linha
		(cWTabAlias)->(dbskip())
	End 
	// Chamar função para replicar dados no BackOffice
//	FwMsgRun(, {||U_xLinkBac(aBkpDds,MV_PAR02) },"Conexão","Gerando dados no BackOffice...")


	RestArea (_aArea)

return .T.

// inicio conversão =============================================================================
//https://www.eclipse.org/forums/index.php/t/118538/
//https://www.eclipse.org/forums/index.php/t/199863/
/*==================================================================================================
  Gera relatorio na a4 por agrupamento.
  MIT044 - Especificacao_de_Personalizacao - Ressarcimento_APD_vs2
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */ 
Static Function fAgruImpr(cPerg, cWTabAlias) 

Local cQuery   := ""
Local nPos     := 1
Local cCol		:= "C_COL"
Local cCab		:= "C_CAB"
Local cAux
Local cLocali := ""
Local nXcc, nTr, nCount, nCont
Local aConvList := {}
Private _cTime     := DtoS(date())+SUBSTR(TIME()	, 1, 2) +SUBSTR(TIME(), 4, 2) +SUBSTR(TIME(), 7, 2)+AllTrim(Str(Int(Seconds()))) 
Private _cArqTmp   := "c:\temp\qry_ressarc"+_cTime+".txt"
Private _resultado := ""
	
	nHandle := MsfCreate(_cArqTmp,0) 

	//Monta cxCC_ com todos os centros de custos envolvidos no agrupamento
	cxCC_:= " RA_CC IN ("
	For nXcc:= 1 to len(aConven)
		cxCC_+= "'C"+aConven[nXcc,4]+"',"
	Next
	cxCC_:= Substr(cxCC_,1,len(cxCC_)-1)
	cxCC_+= " ) "

	// seleciono os funcionarios a serem impressos e convenente ativo o qual esta vinculado
	cQuery := U_fC21QSRA() 
	
	If SELECT("TRB") > 0
		TRB->( dbclosearea() )
	Endif
	
	TCQUERY cQuery NEW ALIAS "TRB" 
	COUNT TO nCount	
			
	ProcRegua(nCount)
	
	TRB->(dbgotop())

	While TRB->( !Eof() ) 
	
		IncProc( TRB->RA_FILIAL+" - Conv: "+alltrim(CTT_DESC01)+CRLF+"Nome: "+TRB->RA_NOME)	    				  
		//aadd(aLog,"Unidade: "+TRB->RA_FILIAL+" - Convenente: "+alltrim(CTT_DESC01)+" - Nome: "+TRB->RA_NOME)	    				  
	
		// busco os ids de provisao para pesquisa, onde o convenente pode provisionar ou nao.
		// O aConven foi montado na fxAgrupa() no CGPER14.prw
		u_fxIdProv( if(!empty(TRB->ZZF_MO),TRB->ZZF_MO,TRB->ZZC_MO) )

		// busca os valores por funcionario ja colunando as verbas que foram encontradas, montando a TSRDC.
		U_fxVlrGrp(aConven[nxConv,6],if(MV_PAR07==1,"A","N"), if(!empty(TRB->ZZF_MO),TRB->ZZF_MO,TRB->ZZC_MO) )
		
		nxDifTot := nxsubTot := nxFunc:= 0
		lAchouSub := .F.
		
        // verifico na TSRDC se o funcionario tem valores a imprimir, basta ter uma verba com valor que sera impresso o registro.		
		If SELECT("TSRDC") == 0 .or. TSRDC->( Eof() )
    		TRB->( dbSkip() )
    		Loop
		Endif             

		//Processa a TSRDC que tem os valores colunados do funcionario
		TSRDC->( dbgotop() )	 
		While TSRDC->( !Eof() ) 
		
			lTemValor := .t.

			//Despreza quando demitido sem movimento
			If !empty(TRB->RA_DEMISSA) .and. left(TRB->RA_DEMISSA,6) < MV_PAR02
				lTemValor := .f.
				For nTr:= 1 to len(aGrupos)
					If TSRDC->&(aGrupos[nTr,1]) > 0
						lTemValor := .t.
						Exit
					EndIf
				Next nTr
			EndIf			
				 
			If lTemValor			
		
				// abre worktable do dataset
				RecLock( cWTabAlias, .T. )
					// passando dados para dataset
					( cWTabAlias )->C_MAT		:= TRB->RA_MAT
					( cWTabAlias )->C_NOME		:= TRB->RA_NOME
					( cWTabAlias )->C_ADMISS	:= DTOC( STOD( TRB->RA_ADMISSA ) )
					( cWTabAlias )->C_DEMISS	:= if(left(TRB->RA_DEMISSA,6) > MV_PAR02,dtoc(ctod("//")),DTOC( STOD( TRB->RA_DEMISSA ) ))
					( cWTabAlias )->C_CODCONV	:= SUBSTR(TRB->RA_CC,2,4)
					( cWTabAlias )->C_CCDESC	:= TRB->ZZC_RAZAO 
					( cWTabAlias )->C_CCDESCRD	:= "Nome reduzido: "+TRB->ZZC_DESCR+" ("+TRB->RA_CC+")"
					( cWTabAlias )->C_CODLOCA	:= SUBSTR(TRB->RA_CC,6,4)
					// Localidade
	 				( cWTabAlias )->C_DESCLOC	:= TRB->ZZF_DESCR
					( cWTabAlias )->C_TELELOC	:= TRB->ZZF_TELEF
					( cWTabAlias )->C_CNPJLOC	:= TRANSFORM( TRB->ZZF_CNPJ, "@R 99.999.999/9999-99" )
					( cWTabAlias )->C_MAILLOC	:= TRB->ZZF_EMAILR 
					cxSMunic := ''	
					If (nPos := Ascan(aMuni,{|x| x[1] == TRB->ZZF_UF .And. x[2] == TRB->ZZF_CODMUN })) > 0
						cxSMunic := aMuni[nPos,3]
					Endif  
					( cWTabAlias )->C_ENDELOC	:= alltrim(TRB->ZZF_ENDERE) + " - " + alltrim(TRB->ZZF_BAIRRO) + " - " + alltrim(cxSMunic)
					// Setor
					( cWTabAlias )->C_SETOR		:= TRB->RA_XSETOR
					if TRB->RA_XSETOR <> "        "
						( cWTabAlias )->C_SETORDSC	:= TRB->ZZI_DESCR
					else
						( cWTabAlias )->C_SETORDSC	:= "VAZIO"
					endif
					( cWTabAlias )->C_MESANO	:= MV_PAR02
					
						//abro a tabela de verbas para buscar a coluna correspondente.
						nTotal := 0
						For nTr:= 1 to len(aGrupos)
							
							// preenche colunas de valor no data set C_COL1 até C_COL22
							// monta nome de coluna
							cAux := cCol + cValToChar(nTr)
							// preenche valor
							( cWTabAlias )->&( cAux ) := round(TSRDC->&(aGrupos[nTr,1]),2)
							
							// verifica se é total e armazena em campo separado
							nTotal := 0
							if ( "TOT" $ alltrim( aGrupos[nTr,1] ) )
								For nCont := 1 to nTr
									nTotal += round(TSRDC->&(aGrupos[nCont,1]),2)
								next
								( cWTabAlias )->C_TOT 		:= nTotal
								( cWTabAlias )->&( cAux ) 	:= nTotal
								
								//Adiciona codigo do convenente no array aConvList para controle 
								//de quantos convenentes estao no mesmo agrupamento
						 		If !(nPos := Ascan(aConvList,{|x| x == SUBSTR(TRB->RA_CC,2,4) })) > 0
							 		aAdd(aConvList, SUBSTR(TRB->RA_CC,2,4)) 			
						 		EndIf
						 		
								// informacoes utilizadas no totalizador final
								cxCabTot:= Iif(Empty(TRB->ZZC_GRUPO), TRB->ZZF_GRUPO, TRB->ZZC_GRUPO)
								nPos:= 0
						 		If !(nPos := Ascan(aTotais,{|x| x[1] == "Agrupador" .And. x[2] == cxCabTot })) > 0
							 		aAdd(aTotais, { "Agrupador", cxCabTot, nxFunc+= 1, nTotal, nAcresc*len(aConvList), nDescon*len(aConvList)} ) 			
						 		Else 
									aTotais[nPos,3]+= 1						 		                                                                       
							 		aTotais[nPos,4]+= nTotal
									aTotais[nPos,5]:= nAcresc*len(aConvList)
									aTotais[nPos,6]:= nDescon*len(aConvList)
						 		Endif     

							Else									

								// totalizando a coluna SUbTotal
								nxSubTot += round(TSRDC->&(aGrupos[nTr,1]),2)
								
								If "SUB" $  aGrupos[nTr,1]      
									( cWTabAlias )->&( cAux ) := nxSubTot
								Endif 
							
							EndIf

							// monta nome de coluna de cabeçalho
							cAux := cCab + cValToChar(nTr)
							// preenche nome coluna
							( cWTabAlias )->&( cAux ) := alltrim( aGrupos[nTr,2] )
							
						Next 
						
						// teste: preencher com valor fixo para comparar
						//	( cWTabAlias )->&( cAux ) := alltrim( aconven[nxConv,5,nTr,2] )
						For nTr := nTr to 22
							// monta nome de coluna de cabeçalho com valor padrão de referência
							cAux := cCab + cValToChar(nTr)
							( cWTabAlias )->&( cAux ) := "VAZIO"
						Next
						
				//fecha worktable
				( cWTabAlias )->( MsUnlock() )
				nContRegs++
				nContTotal++
				
			EndIf
			
			TSRDC->( dbSkip() )	               
		EndDo                         
					
		If Select("TSRDC") <> 0 
			DbSelectArea("TSRDC")
			DbCloseArea()
		Endif   			

	 TRB->( dbSkip() )
		
	EndDo   
	
	// fecho as tabelas
	If Select("TRB") <> 0                              
		DbSelectArea("TRB")
		DbCloseArea()
	Endif  

	If Select("TZZH") <> 0 
		DbSelectArea("TZZH")
		DbCloseArea()
	Endif   		 		

Return     

/*==================================================================================================
  Gera relatorio na a4 - De-Ate
  MIT044 - Especificacao_de_Personalizacao - Ressarcimento_APD_vs2
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */ 
Static Function fResImpr(cWTabAlias) 

Local cQuery   := ""
Local c_Grpo   := ""
Local cCol	   := "C_COL"
Local cCab	   := "C_CAB"
Local cAux
Local nCont, nCount, nProxConv, nAux
Local nTotal, nTr

Private axCCus     := {}
Private cxCusto    := ""
Private _cTime     := DtoS(date())+SUBSTR(TIME()	, 1, 2) +SUBSTR(TIME(), 4, 2) +SUBSTR(TIME(), 7, 2)+AllTrim(Str(Int(Seconds()))) 
Private _cArqTmp   := "c:\temp\qry_ressarc"+_cTime+".txt"
Private _resultado := ""
	
	lAchouSub := .F.
	
	nHandle := MsfCreate(_cArqTmp,0) 

	/* ajusto o parametro p/query
	cxCC_:= " RA_CC IN ('" + aConven[nxConv,4] + "'"
	nAux := nxConv+1
	For nProxConv := nAux to len(aConven)
		If aConven[nProxConv,1] == aConven[nxConv,1]
			cxCC_ += ",'"+aConven[nProxConv,4]+"'"
			nxConv := nProxConv
		Else
			exit
		EndIf	
	Next nProxConv
	cxCC_+= ") "
	*/
	cxCC_:=" RA_CC IN ("+fSqlIn(aConven[nxConv,7],9)+") "   
	
	// seleciono os funcionarios a serem impressos e convenente ativo o qual esta vinculado 
	cQuery := U_fC21QSRA() 

	If SELECT("TRB") > 0
		TRB->( dbclosearea() )
	Endif
	
	TCQUERY cQuery NEW ALIAS "TRB"  
	COUNT TO nCount	
			
	ProcRegua(nCount)
	
	TRB->(dbgotop())
	
	While TRB->( !Eof() )                              
		
		IncProc( TRB->RA_FILIAL+" - Conv: "+alltrim(CTT_DESC01)+CRLF+"Nome: "+TRB->RA_NOME)	    				  
		//aadd(aLog,"Unidade: "+TRB->RA_FILIAL+" - Convenente: "+alltrim(CTT_DESC01)+" - Nome: "+TRB->RA_NOME)	    				  
	    
		// busco os ids de provisao para pesquisa, onde o convenente pode provisionar ou nao.
		u_fxIdProv( if(!empty(TRB->ZZF_MO),TRB->ZZF_MO,TRB->ZZC_MO) )
	
	    // busca os valores por funcionario ja colunando as verbas que foram encontradas, montando a TSRDC.
		U_fxVlrGrp(aConven[nxConv,6],if(MV_PAR07==1,"A","N"), if(!empty(TRB->ZZF_MO),TRB->ZZF_MO,TRB->ZZC_MO) )

		nxDifTot := nxSubTot:= nxFunc:= 0
		lAchouSub:= .F.
		
        // verifico na TSRDC se o funcionario tem valores a imprimir, basta ter uma verba com valor que sera impresso o registro.		
		If SELECT("TSRDC") == 0 .or. TSRDC->( Eof() )
    		TRB->( dbSkip() )
    		Loop
		Endif             

		TSRDC->( dbgotop() )	 
		While TSRDC->( !Eof() ) 

			lTemValor := .t.

			//Despreza quando demitido sem movimento
			If !empty(TRB->RA_DEMISSA) .and. left(TRB->RA_DEMISSA,6) < MV_PAR02
				lTemValor := .f.
				For nTr:= 1 to len(aconven[nxConv,6])
					If TSRDC->&(aconven[nxConv,6,nTr,1]) > 0
						lTemValor := .t.
						Exit
					EndIf
				Next nTr
			EndIf			
				 
			If lTemValor			

				// abre worktable do dataset
				RecLock( cWTabAlias, .T. )
					// passando dados para dataset
					( cWTabAlias )->C_MAT		:= TRB->RA_MAT
					( cWTabAlias )->C_NOME		:= TRB->RA_NOME
					( cWTabAlias )->C_ADMISS	:= DTOC( STOD( TRB->RA_ADMISSA ) )
					( cWTabAlias )->C_DEMISS	:= if(left(TRB->RA_DEMISSA,6) > MV_PAR02,dtoc(ctod("//")),DTOC( STOD( TRB->RA_DEMISSA ) ))
					( cWTabAlias )->C_CODCONV	:= SUBSTR(TRB->RA_CC,2,4)
					( cWTabAlias )->C_CCDESC	:= TRB->ZZC_RAZAO //+ "Nome reduzido: "+TRB->ZZC_DESCR+" ("+TRB->RA_CC+")"
					( cWTabAlias )->C_CCDESCRD	:= "Nome reduzido: "+TRB->ZZC_DESCR+" ("+TRB->RA_CC+")"
					( cWTabAlias )->C_CODLOCA	:= SUBSTR(TRB->RA_CC,6,4)
					// Localidade
	 				( cWTabAlias )->C_DESCLOC	:= TRB->ZZF_DESCR
					( cWTabAlias )->C_TELELOC	:= TRB->ZZF_TELEF
					( cWTabAlias )->C_CNPJLOC	:= TRANSFORM( TRB->ZZF_CNPJ, "@R 99.999.999/9999-99" )
					( cWTabAlias )->C_MAILLOC	:= TRB->ZZF_EMAILR
					cxSMunic := ''	
					If (nPos := Ascan(aMuni,{|x| x[1] == TRB->ZZF_UF .And. x[2] == TRB->ZZF_CODMUN })) > 0
						cxSMunic := aMuni[nPos,3]
					Endif  
					( cWTabAlias )->C_ENDELOC	:= alltrim(TRB->ZZF_ENDERE) + " - " + alltrim(TRB->ZZF_BAIRRO) + " - " + alltrim(cxSMunic)
					// Setor
					( cWTabAlias )->C_SETOR		:= TRB->RA_XSETOR
					if TRB->RA_XSETOR <> "        "
						( cWTabAlias )->C_SETORDSC	:= TRB->ZZI_DESCR
					else
						( cWTabAlias )->C_SETORDSC	:= "VAZIO"
					endif
					// Parâmetro de Desconto/Acrescimo
					( cWTabAlias )->C_DESCON	:= nDescon
					( cWTabAlias )->C_ACRESC	:= nAcresc
					( cWTabAlias )->C_MESANO	:= MV_PAR02
					
						//abro a tabela de verbas para buscar a coluna correspondente.
						nTotal := 0
						For nTr:= 1 to len(aconven[nxConv,6]) 
							
							// preenche colunas de valor no data set C_COL1 até C_COL22
							// monta nome de coluna
							cAux := cCol + cValToChar(nTr)
							// preenche valor
							( cWTabAlias )->&( cAux ) := round(TSRDC->&(aconven[nxConv,6,nTr,1]),2)
							
							// verifica se é total e armazena em campo separado
							nTotal := 0
							if (alltrim( aconven[nxConv,6,nTr,2] ) = "TOTAL")
								For nCont := 1 to nTr
									nTotal += round(TSRDC->&(aconven[nxConv,6,nCont,1]),2)
								next
								( cWTabAlias )->C_TOT 		:= nTotal
								( cWTabAlias )->&( cAux ) 	:= nTotal
								
								// informacoes utilizadas no totalizador final
								cxCabTot:= aConven[nxConv,4]
								nPos:= 0
						 		If !(nPos := Ascan(aTotais,{|x| x[1] == "Individual" .And. x[2] == cxCabTot })) > 0
							 		aAdd(aTotais, { "Individual", cxCabTot, nxFunc+= 1, nTotal, nAcresc, nDescon} ) 			
						 		Else                                                                        
							 		aTotais[nPos,3]+= 1
							 		aTotais[nPos,4]+= nTotal
						 		Endif    									

							Else									
								// totalizando a coluna SUbTotal
								nxSubTot += round(TSRDC->&(aconven[nxConv,6,nTr,1]),2)
								
								If "SUB" $  aconven[nxConv,6,nTr,1] 
									( cWTabAlias )->&( cAux ) := nxSubTot
								Endif 
									
							EndIf
							
							// monta nome de coluna de cabeçalho
							cAux := cCab + cValToChar(nTr)
							// preenche valor
							( cWTabAlias )->&( cAux ) := alltrim( aconven[nxConv,6,nTr,2] )
							
							
						Next 
						
						// loop: preencher com valor fixo para comparar dentro do BIRT
						For nTr := nTr to 22
							// monta nome de coluna de cabeçalho com valor padrão de referência
							cAux := cCab + cValToChar(nTr)
							( cWTabAlias )->&( cAux ) := "VAZIO"
						Next
						
				//fecha worktable
				( cWTabAlias )->( MsUnlock() )
				nContRegs++
				nContTotal++
			
			EndIf

			TSRDC->( dbSkip() )	               
		EndDo                         			
		
		If Select("TSRDC") <> 0 
			DbSelectArea("TSRDC")
			DbCloseArea()
		Endif   			

	 TRB->( dbSkip() )
		
	EndDo   
	
	// fecho as tabelas
	If Select("TRB") <> 0 
		DbSelectArea("TRB")
		DbCloseArea()
	Endif  

	If Select("TZZH") <> 0 
		DbSelectArea("TZZH")
		DbCloseArea()
	Endif   													
				
Return

/*==================================================================================================
  Busca valores do funcionario por grupo, podendo estar no SRC ou SRD, qto a rescisao estará integrada
  com o roteiro FOL e estará gravado no SRC.
  MIT044 - Especificacao_de_Personalizacao - Ressarcimento_APD_vs2
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */
User Function fxVlrGrp(aXXGRP,cTipo,cMO)

Local nr
Local aArea    := getarea()
Local aAreaZZC := ZZC->(getarea())
Local cPulaSRC := ''
Local cPulaSRD := ''
Local cPulaZRD := ''

//Default cMO := Posicione("ZZC",1,xFilial("ZZC")+substr(TRB->RA_CC,2,4),"ZZC_MO")

cxFilSrd:=TRB->RA_FILIAL
cxMatSrd:=TRB->RA_MAT
cxCCuSrd:=TRB->RA_CC 
cQuery  := ""    
cRetSRD := RetSqlName("SRD")
cRetSRV := RetSqlName("SRV")
cRetSRC := RetSqlName("SRC")
cRetSRT := RetSqlName("SRT")
cRetZRD := RetSqlName("ZRD")
cRetZRT := RetSqlName("ZRT")

//Quando MO provisiona 13o + Ferias completa, permite somente as verba que nao estejam configuradas como 13o e Ferias
If cMO $ "04*05*06"
	cPulaSRC := " and RV_REF13<>'S' and RV_REFFER<>'S'"
	cPulaSRD := " and RV_REF13<>'S' and RV_REFFER<>'S'"
	cPulaZRD := " and RV_REF13<>'S' and RV_REFFER<>'S'"
//Quando MO provisiona 13o + Ferias (somente 1/3), permite somente as verbas que nao estejam configuradas 
//para 13o e as de ferias que nao contenham 1/3 na descricao e que nao seja de fechamento
ElseIf cMO == '07'
	cPulaSRC := " and RV_REF13<>'S' and (RV_REFFER<>'S' or (RV_REFFER='S' and RV_DESC not like '%1/3%' and RC_TIPO2<>'F'))"
	cPulaSRD := " and RV_REF13<>'S' and (RV_REFFER<>'S' or (RV_REFFER='S' and RV_DESC not like '%1/3%' and RD_TIPO2<>'F'))"
	cPulaZRD := " and RV_REF13<>'S' and (RV_REFFER<>'S' or (RV_REFFER='S' and RV_DESC not like '%1/3%' and ZRD_TIPO2<>'F'))"
//Qualquer outra MO, permite qualquer verba, condicionando apenas que se for de ferias nao pode ser de fechamento
Else
	cPulaSRC := " and (RV_REFFER<>'S' or (RV_REFFER='S' and RC_TIPO2<>'F'))"
	cPulaSRD := " and (RV_REFFER<>'S' or (RV_REFFER='S' and RD_TIPO2<>'F'))"
	cPulaZRD := " and (RV_REFFER<>'S' or (RV_REFFER='S' and ZRD_TIPO2<>'F'))"
EndIf

_resultado:= ""
cQuery := " SELECT "

//Quando folha antecipada ou repactuacao
If cTipo $ 'A/R' 

	For nr:= 1 to len(aXXGRP) 
		 cQuery   += "(SELECT SUM ("+aXXGRP[nr,1]+") "+aXXGRP[nr,1]+" FROM ( SELECT SUM( CASE WHEN RV_TIPOCOD in ('1','3') THEN ZRD_VALOR WHEN RV_TIPOCOD in ('2','4') THEN ZRD_VALOR*-1 ELSE 0 END) "+aXXGRP[nr,1] 
		 cQuery   += " FROM "+ cRetZRD + " ZRD"
		 cQuery   += " INNER JOIN "+ cRetSRV + " SRV ON RV_COD = ZRD_PD and SRV.D_E_L_E_T_ = ''" + cPulaZRD 
		 cQuery   += " WHERE ZRD.D_E_L_E_T_ = ''"	
		 cQuery   += " AND ZRD_PD IN (SELECT RV_COD FROM "+ cRetSRV + " SRV WHERE SRV.D_E_L_E_T_ = '' AND RV_XGRUPO LIKE '%"+aXXGRP[nr,1]+"%')"
		 cQuery   += " AND ZRD_DATARQ = '"+MV_PAR02+"'"
		 cQuery   += " AND ZRD_MAT = '"+cxMatSrd+"'"
		 cQuery   += " AND ZRD_CC = '"+cxCCuSrd+"'"
		 cQuery   += " AND ZRD_FILIAL = '"+cxFilSrd+"'"
		 cQuery   += " AND ZRD_ROTEIR in ('FOL','131','132')"	 
		 cQuery   += " AND ZRD_TIPCAL = '" + cTipo + "'"
		 // caso tenha a coluna provisoes buscar no movimento atual menos o movimento anterior.
		 If aXXGRP[nr,1] $ "P13*PFE"
		 	If aXXGRP[nr,1] == "P13"
		 		cxPrvAnt:= cIds13oP 
		 		cxPrvMes:= cIds13oP + "," + cIds13oN 
		 	Else
			 	cxPrvAnt:= cIdsFerP + "," + cIdsTerc 
			 	cxPrvMes:= cIdsFerP + "," + cIdsTerc + "," + cIdsFerN + "," + cIdsTerB   			 	
		 	Endif
		 	
		 	//nao trazer as provisoes novamente qdo for rescisao complementar - 22/06/20
		 	If !Empty(cxPrvMes) .And. ( MV_PAR02 <= left(TRB->RA_DEMISSA,6)  .or. Empty(TRB->RA_DEMISSA) )
				 cQuery   += " UNION" 
				 cQuery   += " SELECT SUM(ZRT_VALOR) "+aXXGRP[nr,1]   
				 cQuery   += " FROM "+ cRetZRT + " ZRT"
				 cQuery   += " INNER JOIN "+ cRetSRV + " SRV ON RV_COD = ZRT_VERBA and SRV.D_E_L_E_T_ = ''" 
				 cQuery   += " WHERE ZRT.D_E_L_E_T_ = ''"
				 cQuery   += " AND ZRT_VERBA IN (SELECT RV_COD FROM " + cRetSRV + " SRV WHERE SRV.D_E_L_E_T_ = '' AND RV_CODFOL IN ("+cxPrvMes+"))"  
				 cQuery   += " AND SUBSTRING(ZRT_DATACA,1,6) = '"+MV_PAR02+"'"
				 cQuery   += " AND ZRT_MAT = '"+cxMatSrd+"'"
			//	 cQuery   += " AND ZRT_CC = '"+cxCCuSrd+"'"
			//	 cQuery   += " AND ZRT_FILIAL = '"+cxFilSrd+"'"                          
			//	 cQuery   += " AND ZRT_TIPCAL = '" + cTipo + "'"
			Endif         
			If !Empty(cxPrvAnt) .And. ( MV_PAR02 <= left(TRB->RA_DEMISSA,6)  .or. Empty(TRB->RA_DEMISSA) )
				 cxPerAnt := cValtoChar(AnoMes(monthSub(stod(MV_PAR02+"01"),1)))
/*
				 cQuery   += " UNION"
				 cQuery   += " SELECT SUM(ZRT_VALOR*-1) "+aXXGRP[nr,1]   
				 cQuery   += " FROM "+ cRetZRT + " ZRT"
				 cQuery   += " INNER JOIN "+ cRetSRV + " SRV ON RV_COD = ZRT_VERBA and SRV.D_E_L_E_T_ = ''" 
				 cQuery   += " WHERE ZRT.D_E_L_E_T_ = ''"
				 cQuery   += " AND ZRT_VERBA IN (SELECT RV_COD FROM " + cRetSRV + " SRV WHERE SRV.D_E_L_E_T_ = '' AND RV_CODFOL IN ("+cxPrvAnt+"))"  
				 cQuery   += " AND SUBSTRING(ZRT_DATACA,1,6) = '"+cxPerAnt+"'"
				 cQuery   += " AND ZRT_MAT = '"+cxMatSrd+"'"
			//	 cQuery   += " AND ZRT_CC = '"+cxCCuSrd+"'"
			//	 cQuery   += " AND ZRT_FILIAL = '"+cxFilSrd+"'"
			//	 cQuery   += " AND ZRT_TIPCAL = '" + cTipo + "'"
*/
				 cQuery   += " UNION"
				 cQuery   += " SELECT SUM(RT_VALOR*-1) "+aXXGRP[nr,1]   
				 cQuery   += " FROM "+ cRetSRT + " SRT"
				 cQuery   += " INNER JOIN "+ cRetSRV + " SRV ON RV_COD = RT_VERBA and SRV.D_E_L_E_T_ = ''" 
				 cQuery   += " WHERE SRT.D_E_L_E_T_ = ''"
				 cQuery   += " AND RT_VERBA IN (SELECT RV_COD FROM "+ cRetSRV + " SRV WHERE SRV.D_E_L_E_T_ = '' AND RV_CODFOL IN ("+cxPrvAnt+"))"  
				 cQuery   += " AND SUBSTRING(RT_DATACAL,1,6) = '"+cxPerAnt+"'"
				 cQuery   += " AND RT_MAT = '"+cxMatSrd+"'"
			//	 cQuery   += " AND RT_CC = '"+cxCCuSrd+"'"
			//	 cQuery   += " AND RT_FILIAL = '"+cxFilSrd+"'"
			Endif
		 Endif   
		 		              
		 cQuery   += ") AS " + aXXGRP[nr,1] + ") "+ aXXGRP[nr,1] + ","
		 
	Next	

//Quando for folha normal
Else

	For nr:= 1 to len(aXXGRP) 
		 cQuery   += "(SELECT SUM ("+aXXGRP[nr,1]+") "+aXXGRP[nr,1]+" FROM ( SELECT SUM( CASE WHEN RV_TIPOCOD in ('1','3') THEN RD_VALOR WHEN RV_TIPOCOD in ('2','4') THEN RD_VALOR*-1 ELSE 0 END) "+aXXGRP[nr,1] 
		 cQuery   += " FROM "+ cRetSRD + " SRD"
		 cQuery   += " INNER JOIN "+ cRetSRV + " SRV ON RV_COD = RD_PD and SRV.D_E_L_E_T_ = ''" + cPulaSRD
		 cQuery   += " WHERE SRD.D_E_L_E_T_ = ''"	
		 cQuery   += " AND RD_PD IN (SELECT RV_COD FROM "+ cRetSRV + " SRV WHERE SRV.D_E_L_E_T_ = '' AND RV_XGRUPO LIKE '%"+aXXGRP[nr,1]+"%')"
		 cQuery   += " AND RD_DATARQ = '"+MV_PAR02+"'"
		 cQuery   += " AND RD_MAT = '"+cxMatSrd+"'"
		 cQuery   += " AND RD_CC = '"+cxCCuSrd+"'"
		 cQuery   += " AND RD_FILIAL = '"+cxFilSrd+"'"
		 cQuery   += " AND RD_ROTEIR in ('FOL','131','132')"	 
		 cQuery   += " UNION"  
		 cQuery   += " SELECT SUM(CASE WHEN RV_TIPOCOD in ('1','3') THEN RC_VALOR WHEN RV_TIPOCOD in ('2','4') THEN RC_VALOR*-1 ELSE 0 END) "+aXXGRP[nr,1] 
		 cQuery   += " FROM "+ cRetSRC + " SRC"
		 cQuery   += " INNER JOIN "+ cRetSRV + " SRV ON RV_COD = RC_PD and SRV.D_E_L_E_T_ = ''" + cPulaSRC 
		 cQuery   += " WHERE SRC.D_E_L_E_T_ = ''"	
		 cQuery   += " AND RC_PD IN (SELECT RV_COD FROM "+ cRetSRV + " SRV WHERE SRV.D_E_L_E_T_ = '' AND RV_XGRUPO LIKE '%"+aXXGRP[nr,1]+"%')"
		 cQuery   += " AND RC_PERIODO = '"+MV_PAR02+"'"	
		 cQuery   += " AND RC_MAT = '"+cxMatSrd+"'"
		 cQuery   += " AND RC_CC = '"+cxCCuSrd+"'"
		 cQuery   += " AND RC_FILIAL = '"+cxFilSrd+"'"
		 cQuery   += " AND RC_ROTEIR in ('FOL','131','132')"
		 // caso tenha a coluna provisoes buscar no movimento atual menos o movimento anterior.
		 If aXXGRP[nr,1] $ "P13*PFE"
		 	If aXXGRP[nr,1] == "P13"
		 		cxPrvAnt:= cIds13oP 
		 		cxPrvMes:= cIds13oP + "," + cIds13oN 
		 	Else
			 	cxPrvAnt:= cIdsFerP + "," + cIdsTerc 
			 	cxPrvMes:= cIdsFerP + "," + cIdsTerc + "," + cIdsFerN + "," + cIdsTerB   			 	
		 	Endif
		 	
		 	//nao trazer as provisoes novamente qdo for rescisao complementar - 22/06/20
		 	If !Empty(cxPrvMes) .And. ( MV_PAR02 <= left(TRB->RA_DEMISSA,6)  .or. Empty(TRB->RA_DEMISSA) )
				 cQuery   += " UNION" 
				 cQuery   += " SELECT SUM(RT_VALOR) "+aXXGRP[nr,1]   
				 cQuery   += " FROM "+ cRetSRT + " SRT"
				 cQuery   += " INNER JOIN "+ cRetSRV + " SRV ON RV_COD = RT_VERBA and SRV.D_E_L_E_T_ = ''" 
				 cQuery   += " WHERE SRT.D_E_L_E_T_ = ''"
				 cQuery   += " AND RT_VERBA IN (SELECT RV_COD FROM "+ cRetSRV + " SRV WHERE SRV.D_E_L_E_T_ = '' AND RV_CODFOL IN ("+cxPrvMes+"))"  
				 cQuery   += " AND SUBSTRING(RT_DATACAL,1,6) = '"+MV_PAR02+"'"
				 cQuery   += " AND RT_MAT = '"+cxMatSrd+"'"
			//	 cQuery   += " AND RT_CC = '"+cxCCuSrd+"'"       comentado p/ qdo haver transferencia pegar filial/cc destino + origem
			//	 cQuery   += " AND RT_FILIAL = '"+cxFilSrd+"'"                          
			Endif         
			If !Empty(cxPrvAnt) .And. ( MV_PAR02 <= left(TRB->RA_DEMISSA,6)  .or. Empty(TRB->RA_DEMISSA) )
				 cxPerAnt := cValtoChar(AnoMes(monthSub(stod(MV_PAR02+"01"),1)))
				 cQuery   += " UNION"
				 cQuery   += " SELECT SUM(RT_VALOR*-1) "+aXXGRP[nr,1]   
				 cQuery   += " FROM "+ cRetSRT + " SRT"
				 cQuery   += " INNER JOIN "+ cRetSRV + " SRV ON RV_COD = RT_VERBA and SRV.D_E_L_E_T_ = ''" 
				 cQuery   += " WHERE SRT.D_E_L_E_T_ = ''"
				 cQuery   += " AND RT_VERBA IN (SELECT RV_COD FROM "+ cRetSRV + " SRV WHERE SRV.D_E_L_E_T_ = '' AND RV_CODFOL IN ("+cxPrvAnt+"))"  
				 cQuery   += " AND SUBSTRING(RT_DATACAL,1,6) = '"+cxPerAnt+"'"
				 cQuery   += " AND RT_MAT = '"+cxMatSrd+"'"
			//	 cQuery   += " AND RT_CC = '"+cxCCuSrd+"'"
			//	 cQuery   += " AND RT_FILIAL = '"+cxFilSrd+"'"
			Endif
		 Endif   
		 		              
		 cQuery   += ") AS " + aXXGRP[nr,1] + ") "+ aXXGRP[nr,1] + ","
		 
	Next	

EndIf

cQuery := Substr(cQuery ,1,len(cQuery)-1)

//grava arquivo com resultado da query para analise.
_resultado:=cQuery+ CRLF + CRLF
fWrite(nHandle, _resultado)      

RestArea(aAreaZZC)
RestArea(aArea)

If SELECT("TSRDC") > 0
	TSRDC->( dbclosearea() )
Endif

TCQUERY cQuery NEW ALIAS "TSRDC" 

Return()      


/*==================================================================================================
  Busca Verbas de Provisao
  MIT044 - Especificacao_de_Personalizacao - Ressarcimento_APD_vs2
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
@campo     ZZC_MO - f3 TABELA _0 no SX5
           01 Funcionário/Estagiário/Aprendiz                        
           02 APRENDIZ CEF (INATIVO)                                 
           03 APD PROVISÃO SEM RESSARCIMENTO                         
           04 APD PROVISÃO COM RESSARCIMENTO                         
           05 APD PROVISÃO BANCO DO BRASIL                           
           06 APD PROVISÃO CAIXA                                     
           07 APD 1/3 FÉRIAS COM RESSARCIMENTO                       
//================================================================================================== */
User Function fxIdProv(cTipo) 

cIds13oP:=cIds13oN:=""
cIdsFerP:=cIdsTerB:=cIdsFerN:=CIDSTERC:=""

If Funname() != "CGPER25" .and. left(TRB->RA_DEMISSA,6) == MV_PAR02
	cIds13oP:=cIds13oN:="'XXX'"  // caso tenha selecionado um layout que tenha as colunas PFE/P13 no layout, porem p/a mao de obra (ZZC_MO) nao provisiona devo manter a coluna na query entao coloco "XXX".
	cIdsFerP:=cIdsTerB:=cIdsFerN:=CIDSTERC:="'XXX'"

Else

	If cTipo $ "04*05*06"
		 
		// 13º 
		cIds13oP:="'0136',"	// Provisao de 13o Salario
		cIds13oP+="'0267',"	// Adicional Provisao de 13o Salario
		cIds13oP+="'0268',"	// 1a. Parcela 13o Provisao
	//	cIds13oP+="'0137',"	// INSS Provisao 13o Salario
		cIds13oP+="'0138',"	// FGTS Provisao 13o Salario
	//	cIds13oP+="'0421',"	// PIS Provisao 13o Salario
		cIds13oP+="'0966',"	// Prov. Mês 13o Salário
		cIds13oP+="'0967',"	// Prov. Mês Adcional de 13o Salári
		cIds13oP+="'0968',"	// 1a. Parcela 13o Provisao
	//	cIds13oP+="'0969',"	// Prov. Mês INSS de 13o Salário
		cIds13oP+="'0970',"	// Prov. Mês FGTS de 13o Salário
	//	cIds13oP+="'0971',"	// Prov. Mês PIS de 13o SalárioaCodFol[139,
		cIds13oP+="'0269',"	// Correcao Adicional Provisao de 13o Salar
	//	cIds13oP+="'0140',"	// Correcao INSS Provisao 13o Salario
		cIds13oP+="'0141'"	// Correcao FGTS Provisao 13o Salario
	//	cIds13oP+="'0422'"	// Correcao PIS Provisao 13o Salario
		
		// 13º Baixas
		cIds13oN:="'0332',"	// Baixa Provisao 13o Salario
		cIds13oN+="'0333',"	// Baixa Adicional Provisao de 13o Salario
	//	cIds13oN+="'0334',"	// Baixa Antecipacao 1a Parcela do 13o Sala
	//	cIds13oN+="'0335',"	// Baixa Inss Provisao 13o Salario
		cIds13oN+="'0336'"	// Baixa Fgts Provisao 13o Salario
	//	cIds13oN+="'0423',"	// Baixa PIS Provisao 13o Salario
	//	cIds13oN+="'0270',"	// Baixa Provisao 13o Salario Transferido
	//	cIds13oN+="'0271',"	// Baixa Adicional Provisao de 13o Salario 
	//	cIds13oN+="'0272',"	// Baixa Inss Provisao 13o Salario Transfer
	//	cIds13oN+="'0273'"	// Baixa Fgts Provisao 13o Salario Transfer
	//	cIds13oN+="'0424',"	// Baixa PIS Provisao 13o Salario Transferi
	//	cIds13oN+="'0274',"	// Baixa Provisao 13o Salario Rescisao
	//	cIds13oN+="'0275',"	// Baixa Adicional Provisao de 13o Salario 
	//	cIds13oN+="'0276',"	// Baixa Inss Provisao 13o Salario Rescisao
	//	cIds13oN+="'0277'"	// Baixa Fgts Provisao 13o Salario Rescisao
	//	cIds13oN+="'0425'"	// Baixa PIS Provisao 13o Salario Rescisao
		
		// Ferias
		cIdsFerP+="'0130',"	// Provisao de Ferias	
		cIdsFerP+="'0254',"	// Adicional Provisao de Ferias	
	//	cIdsFerP+="'0131',"	// INSS Provisao de Ferias	
		cIdsFerP+="'0132',"	// FGTS Provisao de Ferias	
	//	cIdsFerP+="'0416',"	// PIS Provisao de Ferias	
		cIdsFerP+="'0133',"	// Correcao Provisao de Ferias	
		cIdsFerP+="'0256',"	// Correcao Adicional Provisao de Ferias	
	//	cIdsFerP+="'0134',"	// Correcao INSS Provisao de Ferias	
		cIdsFerP+="'0135',"	// Correcao FGTS Provisao de Ferias	
	//	cIdsFerP+="'0417',"	// Correcao PIS Provisao de Ferias	
		cIdsFerP+="'0960',"	// Prov. Mês Férias	
		cIdsFerP+="'0962',"	// Prov. Mês Adicional de Férias	
	//	cIdsFerP+="'0963',"	// Prov. Mês INSS de Férias	
		cIdsFerP+="'0964',"	// Prov. Mês FGTS de Férias	
	//	cIdsFerP+="'0965',"	// Prov. Mês PIS de Férias	
		cIdsFerP+="'1400',"	//  Provisao de Recesso	
		cIdsFerP+="'1401'"	//  Correcao Provisao de Recesso 
		
		// 1/3 Ferias
		cIdsTerc:= "'0255'," // Um Terco Provisao de Ferias	
		cIdsTerc+= "'0257'," // Correcao Um Terco Provisao de Ferias	
		cIdsTerc+= "'0961'" // Prov. Mês 1/3 de Férias	
		
		// Ferias Baixas
		cIdsFerN+="'0233',"	// Baixa Provisao Ferias	
		cIdsFerN+="'0258',"	// Baixa Adicional Provisao de Ferias	
	//	cIdsFerN+="'0234',"	// Baixa Inss Provisao Ferias	
		cIdsFerN+="'0235',"	// Baixa Fgts Provisao Ferias	
	//	cIdsFerN+="'0418',"	// Baixa PIS Provisao Ferias	
	//	cIdsFerN+="'0239',"	// Baixa Provisao Ferias Transferidos	
	//	cIdsFerN+="'0260',"	// Baixa Adicional Provisao de Ferias Trans	
	//	cIdsFerN+="'0240',"	// Baixa Inss Provisao Ferias Transferidos	
	//	cIdsFerN+="'0241',"	// Baixa Fgts Provisao Ferias Transferidos	
	//	cIdsFerN+="'0419',"	// Baixa PIS Provisao Ferias Transferidos	
		cIdsFerN+="'0262',"	// Baixa Provisao Ferias Rescisao	
		cIdsFerN+="'0263',"	// Baixa Adicional Provisao de Ferias Resci	
	//	cIdsFerN+="'0265',"	// Baixa Inss Provisao Ferias Rescisao	
		cIdsFerN+="'0266',"	// Baixa Fgts Provisao Ferias Rescisao	
	//	cIdsFerN+="'0420',"	// Baixa PIS Provisao Ferias Rescisao	
		cIdsFerN+="'1402',"	// Baixa Provisao Recesso	
		cIdsFerN+="'1403',"	// Baixa Provisao Recesso Transferidos	
		cIdsFerN+="'1404'"	// Baixa Provisao Recesso Rescisao	
		
		// Ferias Baixa 1/3
		cIdsTerB:="'0259',"	// Baixa Um Terco Provisao de Ferias	
	 //	cIdsTerB+="'0261',"	// Baixa Um Terco Provisao de Ferias Transf	
		cIdsTerB+="'0264'"	// Baixa Um Terco Provisao de Ferias Rescis	 
	
	ElseIf cTipo == "07"   // nao provisiona ferias apenas 1/3 
	
		// 13º 
		cIds13oP:="'0136',"	// Provisao de 13o Salario
		cIds13oP+="'0267',"	// Adicional Provisao de 13o Salario
		cIds13oP+="'0268',"	// 1a. Parcela 13o Provisao
	//	cIds13oP+="'0137',"	// INSS Provisao 13o Salario
		cIds13oP+="'0138',"	// FGTS Provisao 13o Salario
	//	cIds13oP+="'0421',"	// PIS Provisao 13o Salario
		cIds13oP+="'0966',"	// Prov. Mês 13o Salário
		cIds13oP+="'0967',"	// Prov. Mês Adcional de 13o Salári
		cIds13oP+="'0968',"	// 1a. Parcela 13o Provisao
	//	cIds13oP+="'0969',"	// Prov. Mês INSS de 13o Salário
		cIds13oP+="'0970',"	// Prov. Mês FGTS de 13o Salário
	//	cIds13oP+="'0971',"	// Prov. Mês PIS de 13o SalárioaCodFol[139,
		cIds13oP+="'0269',"	// Correcao Adicional Provisao de 13o Salar
	//	cIds13oP+="'0140',"	// Correcao INSS Provisao 13o Salario
		cIds13oP+="'0141'"	// Correcao FGTS Provisao 13o Salario
	//	cIds13oP+="'0422'"	// Correcao PIS Provisao 13o Salario
		
		// 13º Baixas
		cIds13oN:="'0332',"	// Baixa Provisao 13o Salario
		cIds13oN+="'0333',"	// Baixa Adicional Provisao de 13o Salario
	//	cIds13oN+="'0334',"	// Baixa Antecipacao 1a Parcela do 13o Sala
	//	cIds13oN+="'0335',"	// Baixa Inss Provisao 13o Salario
		cIds13oN+="'0336'"	// Baixa Fgts Provisao 13o Salario
	//	cIds13oN+="'0423',"	// Baixa PIS Provisao 13o Salario
	//	cIds13oN+="'0270',"	// Baixa Provisao 13o Salario Transferido
	//	cIds13oN+="'0271',"	// Baixa Adicional Provisao de 13o Salario 
	//	cIds13oN+="'0272',"	// Baixa Inss Provisao 13o Salario Transfer
	//	cIds13oN+="'0273'"	// Baixa Fgts Provisao 13o Salario Transfer
	//	cIds13oN+="'0424',"	// Baixa PIS Provisao 13o Salario Transferi
	//	cIds13oN+="'0274',"	// Baixa Provisao 13o Salario Rescisao
	//	cIds13oN+="'0275',"	// Baixa Adicional Provisao de 13o Salario 
	//	cIds13oN+="'0276',"	// Baixa Inss Provisao 13o Salario Rescisao
	//	cIds13oN+="'0277'"	// Baixa Fgts Provisao 13o Salario Rescisao
	//	cIds13oN+="'0425'"	// Baixa PIS Provisao 13o Salario Rescisao
	    
		// 1/3 Ferias
		cIdsTerc:= "'0255'," // Um Terco Provisao de Ferias	
		cIdsTerc+= "'0257'," // Correcao Um Terco Provisao de Ferias	
		cIdsTerc+= "'0961'" // Prov. Mês 1/3 de Férias	 
	
		// Ferias Baixa 1/3
		cIdsTerB:="'0259',"	// Baixa Um Terco Provisao de Ferias	
	//	cIdsTerB+="'0261',"	// Baixa Um Terco Provisao de Ferias Transf	
		cIdsTerB+="'0264'"	// Baixa Um Terco Provisao de Ferias Rescis	 	
	
	    // informei XXX pois em se deixar em branco o retorno sao todas as verbas que nao tem ID.
		cIdsFerP:="'XXX'"
		cIdsFerN:="'XXX'"   
		
	else
		cIds13oP:=cIds13oN:="'XXX'"  // caso tenha selecionado um layout que tenha as colunas PFE/P13 no layout, porem p/a mao de obra (ZZC_MO) nao provisiona devo manter a coluna na query entao coloco "XXX".
		cIdsFerP:=cIdsTerB:=cIdsFerN:=CIDSTERC:="'XXX'"
		
	ENDIF

EndIf

Return


/*==================================================================================================
  Monta Query sobre SRA para utilizacao nos relatorios de ressarcimento e repactuacao
@author     Marcos Pereira
@since      
@param
@version    P12
@return
@project
@client    Ciee 
@campo                            
//================================================================================================== */
User Function fC21QSRA()

Local cQry

    cQry := " SELECT CTT_CUSTO AS RA_CC,RA_FILIAL, RA_NOME, RA_MAT, RA_XSETOR, CTT_DESC01,RA_ADMISSA, RA_DEMISSA, RA_SALARIO, RA_HRSMES, RA_SITFOLH, RA_CIC, RA_DTFIMCT, "
    cQry += " ZZC_CNPJ, ZZC_RAZAO, ZZC_DESCR, ZZC_MO, ZZF_MO, ZZF_DESCR, ZZF_CNPJ, ZZF_UF, ZZF_ENDERE, ZZF_CEP, ZZF_TELEF, ZZF_EMAILR, ZZI_DESCR, ZZD_PCONGE, ZZC_GRUPO, "
    cQry += " ZZF_GRUPO, ZZF_BAIRRO, ZZF_CODMUN, ZZC_NUMCON, ZZF_NUMCON, ZRA_CODSOC "
    cQry += " FROM " + RetSqlName("SRA") + " SRA " 
    cQry += " INNER JOIN " + RetSqlName("CTT") + " CTT ON CTT_CUSTO = "   
    cQry += "  ( Case when 
    cQry += "     (Select RE_CCP  FROM " + RetSqlName("SRE") + " where D_E_L_E_T_ = '' and RE_DATA = (Select max(RE_DATA) FROM "
	cQry += "     " + RetSqlName("SRE") + " where D_E_L_E_T_ = '' and RE_MATP = RA_MAT and left(RE_DATA,6) <= '"+MV_PAR02+"') and RE_MATP = RA_MAT) <> '' "
	cQry += "    then "
	cQry += "     (Select RE_CCP  FROM " + RetSqlName("SRE") + "  where D_E_L_E_T_ = '' and RE_DATA = (Select max(RE_DATA) FROM " + RetSqlName("SRE") + " "
	cQry += "      where D_E_L_E_T_ = '' and RE_MATP = RA_MAT and left(RE_DATA,6) <= '"+MV_PAR02+"') and RE_MATP = RA_MAT) "
	cQry += "    else "
    cQry += "      RA_CC End "
	cQry += "  ) AND CTT.D_E_L_E_T_ = '' " 
	cQry += " INNER JOIN " + RetSqlName("ZZC") + " ZZC ON SUBSTRING(CTT_CUSTO,2,4) = ZZC_CODIGO  AND ZZC.D_E_L_E_T_ = ''  "
	cQry += "    AND (ZZC_DTFIM = '' or left(ZZC_DTFIM,6) >= '"+MV_PAR02+"') "
	cQry += " INNER JOIN " + RetSqlName("ZZD") + " ZZD ON ZZD_CODCON = SUBSTRING(CTT_CUSTO,2,4) AND ZZD_PERINI <= '"+MV_PAR02+"' and (ZZD_PERFIM >= '"+MV_PAR02+"' or ZZD_PERFIM = '')  and ZZD.D_E_L_E_T_ = '' "
	cQry += " INNER JOIN " + RetSqlName("ZZF") + " ZZF ON 'C'+ZZF_CODCON+ZZF_CODIGO = CTT_CUSTO AND ZZF_PERINI = ZZD_PERINI and ZZF.D_E_L_E_T_ = '' " 
	cQry += " LEFT OUTER JOIN " + RetSqlName("ZZI") + " ZZI ON ZZI_CODIGO = RA_XSETOR and ZZI.D_E_L_E_T_ = '' " 
	cQry += " LEFT OUTER JOIN (SELECT DISTINCT ZRA_FILIAL, ZRA_MAT, ZRA_CODSOC FROM " + RetSqlName("ZRA") + " where D_E_L_E_T_ = '')" + " ZRA ON ZRA_MAT = RA_MAT AND ZRA_FILIAL = RA_FILIAL "   
	cQry += " WHERE SRA.D_E_L_E_T_ = ' ' AND "
	cQry +=       " left(RA_ADMISSA,6) <= '"+MV_PAR02+"' and "
	cQry +=       " (RA_DEMISSA = '' or left(RA_DEMISSA,6) >= '"+cDemDesde+"' "
	cQry +=       "   or  "
	cQry +=       "  RA_FILIAL+RA_MAT in "
	cQry +=       "   (SELECT RC_FILIAL+RC_MAT FROM " + RetSqlName("SRC") + " Where RC_FILIAL=RA_FILIAL and RC_MAT=RA_MAT and RC_PERIODO='"+MV_PAR02+"' and RC_ROTEIR = 'FOL' and D_E_L_E_T_ = '' "
	cQry +=       "    UNION "
	cQry +=       "    SELECT RD_FILIAL+RD_MAT FROM " + RetSqlName("SRD") + " Where RD_FILIAL=RA_FILIAL and RD_MAT=RA_MAT and RD_PERIODO='"+MV_PAR02+"' and RD_ROTEIR = 'FOL' and D_E_L_E_T_ = '' "	
	cQry +=       "    ) "
	cQry +=       " ) AND " 
	cQry += "  " + cxCC_ + " "														  		  
	cQry += "	AND SUBSTRING(RA_FILIAL,7,2) = '02' "		
	cQry += "   AND RA_RESCRAI <> '31' "                      // nao trazer os func. que tiveram transferencias para nao duplicar.
	If !empty(MV_PAR10)
		cQry += " and (ZZF_MO = '" + MV_PAR10 + "' or (ZZF_MO='' and ZZC_MO = '" + MV_PAR10 + "'))"
	EndIf
	cQry += " ORDER BY RA_CC, RA_XSETOR, RA_NOME, RA_MAT " 
	
 Return(cQry)
                

/*==================================================================================================
  Monta estrutura para relatorio em excel
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
@campo                            
//================================================================================================== */ 
User Function fxMonExc(cTpDesign,cAgrupador,nx2) 
	Private oProcess
	// Executa o processamento dos arquivos
	oProcess:=	MsNewProcess():New( {|lEnd|  GpfxMonExc(cTpDesign,cAgrupador,nx2) } , "Efetuando geração do Excel" , "Efetuando geração do Excel" )
	oProcess:Activate()
	
Return

Static Function GpfxMonExc(cTpDesign,cAgrupador,nx2) 

Local cQuery   := ""
Local c_Grpo   := ""
Local cCol	   := "C_COL"
Local cCab	   := "C_CAB"
Local nContRegs:= 0
Local cAux
Local nCont, nCount, nProxConv, nAux
Local nTotal, nTr           
Local nX, cArquivo, nPos
Local aTxtSoe	   := {}
Local aBkpDds	   := {}                                                               
Default cAgrupador := ''

Private oExcel     := FWMSEXCEL():New()
Private cTipo      := cResName := "Ressarcimento_"+mv_par02 
Private axCCus     := {}
Private cxCusto    := ""
Private _cTime     := DtoS(date())+SUBSTR(TIME()	, 1, 2) +SUBSTR(TIME(), 4, 2) +SUBSTR(TIME(), 7, 2)+AllTrim(Str(Int(Seconds()))) 
Private _cArqTmp   := "c:\temp\qry_excel_ressarc"+_cTime+".txt" 
Private _resultado := ""        
Private axTot      := {}
Private n_PosFE    := 0
Private	n_Pos13	   := 0
Private n_PosCI    := 0
Private n_PosTot   := 0

// variavel setada pelo no CGPER14 
nxConv := nX2            

//nome do arquivo para cada convenente
If lAgrupa
	cArquivo := cxDiret+"AGRUPAMENTO_"+Alltrim(cAgrupador)+"_"+mv_par02
	cArquivo += "_"+dtos(date())+StrTran(TIME(),":","")+ ".xls"
Else
	cArquivo := cxDiret+Alltrim(Substr(aConven[nxConv,4],2,4))+"_"+strtran(Strtran(Alltrim(aConven[nxConv,3]),"/",""),"\","")+"_"+mv_par02					
	cArquivo += "_"+dtos(date())+StrTran(TIME(),":","")+ ".xls"				
EndIf

//criando o excel
oExcel:AddworkSheet(cTipo)
oExcel:AddTable (cTipo,cResName)

oExcel:AddColumn(cTipo,cResName,"Empresa"                 ,2,1)//1
oExcel:AddColumn(cTipo,cResName,"Unidade" 		          ,2,1)//2
oExcel:AddColumn(cTipo,cResName,"CNPJ"                    ,2,1)//3
oExcel:AddColumn(cTipo,cResName,"Matricula"               ,2,1)//4
oExcel:AddColumn(cTipo,cResName,"Nome"                    ,2,1)//5
oExcel:AddColumn(cTipo,cResName,"Data Admissão"           ,2,4)//6
oExcel:AddColumn(cTipo,cResName,"Data Demissão"           ,2,4)//7
oExcel:AddColumn(cTipo,cResName,"Situação"                ,2,1)//8
//oExcel:AddColumn(cTipo,cResName,"Salário"                 ,2,1)//

For nx:= 1 to len(aConven[nxConv,6])
	//oExcel:AddColumn(cTipo,cResName,alltrim(agrupos[nx,2]),2,1)
	oExcel:AddColumn(cTipo,cResName,alltrim(aConven[nxConv,6,nx,2]),2,1)	
    // armarzena posicoes das colunas para gerar o arquivo SOE
	If "PFE" $  upper(aConven[nxConv,6,nx,1]) 
	    n_PosFE:= nx + 8
	Endif
	
	If "P13" $  upper(aConven[nxConv,6,nx,1]) 
		n_Pos13:= nx + 8
	Endif
	
	If "TOTAL" $  upper(aConven[nxConv,6,nx,1])
		n_PosTot:= nx + 8
	Endif   	
	
	If "INSTITUC" $  upper(aConven[nxConv,6,nx,1])
		n_PosCI:= nx + 8
	Endif         
		
Next nx                                                                              

oExcel:AddColumn(cTipo,cResName,"      "                  ,2,1)//9
oExcel:AddColumn(cTipo,cResName,"Id Mão de Obra"          ,2,1)//10
oExcel:AddColumn(cTipo,cResName,"Mão de Obra"             ,2,1)//11
oExcel:AddColumn(cTipo,cResName,"Descrição do Nome Convenente",2,1)//12
oExcel:AddColumn(cTipo,cResName,"Endereço"                ,2,1)//13
oExcel:AddColumn(cTipo,cResName,"UF"                      ,2,1)//14
oExcel:AddColumn(cTipo,cResName,"Bairro"                  ,2,1)//15
oExcel:AddColumn(cTipo,cResName,"Município"               ,2,1)//16
oExcel:AddColumn(cTipo,cResName,"Telefone"                ,2,1)//17
oExcel:AddColumn(cTipo,cResName,"Email"                   ,2,1)//18
oExcel:AddColumn(cTipo,cResName,"Centro de Custo"         ,2,1)//19 
oExcel:AddColumn(cTipo,cResName,"Salário"                 ,2,1)//20 
oExcel:AddColumn(cTipo,cResName,"Carga Horária"           ,2,1)//21 
oExcel:AddColumn(cTipo,cResName,"CPF"                     ,2,1)//22
oExcel:AddColumn(cTipo,cResName,"Cod.SOC"                 ,2,1)//23
oExcel:AddColumn(cTipo,cResName,"Cod.Setor Cliente"       ,2,1)//24
oExcel:AddColumn(cTipo,cResName,"Descrição Setor do Cliente",2,1)//25
oExcel:AddColumn(cTipo,cResName,"Data Fim do Contrato"    ,2,1)//26
oExcel:AddColumn(cTipo,cResName,"Num.TCA"			      ,2,1)//27

//cria linha de totalizadores por arquivo
For nxColx:= 1 to len(aConven[nxConv,6]) + 27
	If nxColx > 8  .And. nxColx <= len(aConven[nxConv,6])+ 8 // totalizadores apenas nas colunas que nao fixas.
		aAdd(axTot, 0 )
	Else
		aAdd(axTot, "" )	
	Endif 
Next

lAchouSub := .F.

nHandle := MsfCreate(_cArqTmp,0) 

If lYes
	cxCC_:= " RA_CC IN ("
	For nXcc:= 1 to len(aConven)
		cxCC_+= "'C"+aConven[nXcc,4]+"',"
	Next
	cxCC_:= Substr(cxCC_,1,len(cxCC_)-1)
	cxCC_+= " ) "
Else
	cxCC_:=" RA_CC IN ("+fSqlIn(aConven[nxConv,7],9)+") " 
Endif

// seleciono os funcionarios a serem impressos e convenente ativo o qual esta vinculado 
cQuery := U_fC21QSRA() 

If SELECT("TRB") > 0
	TRB->( dbclosearea() )
Endif 

//seta grupos na posicao do array funcao fxAgrupa
If !Empty(mv_par03)
	aConven[nxConv,6]:= aclone(aConven[nxConv,6])
Endif

TCQUERY cQuery NEW ALIAS "TRB"  
COUNT TO nCount	
		
oProcess:SetRegua2(nCount)

TRB->(dbgotop())  

// Reseta dados da variavel
aBkpDds := {}

While TRB->( !Eof() )                              
	
	oProcess:IncRegua2("Uni.: "+TRB->RA_FILIAL+" - Conv.: "+alltrim(CTT_DESC01)+CRLF+"Nome: "+TRB->RA_NOME)	    				  
    
	// busco os ids de provisao para pesquisa, onde o convenente pode provisionar ou nao.
	u_fxIdProv( if(!empty(TRB->ZZF_MO),TRB->ZZF_MO,TRB->ZZC_MO) )

    // busca os valores por funcionario ja colunando as verbas que foram encontradas, montando a TSRDC.
	U_fxVlrGrp(aConven[nxConv,6],if(MV_PAR07==1,"A","N"), if(!empty(TRB->ZZF_MO),TRB->ZZF_MO,TRB->ZZC_MO) )

	nxDifTot := nxSubTot:= nxFunc:= 0
	lAchouSub:= .F.
	
    // verifico na TSRDC se o funcionario tem valores a imprimir, basta ter uma verba com valor que sera impresso o registro.		
	If SELECT("TSRDC") == 0 .or. TSRDC->( Eof() )
    		TRB->( dbSkip() )
    		Loop
	Endif             

	TSRDC->( dbgotop() )	 
	While TSRDC->( !Eof() ) 

		lTemValor := .t. 
		ADADOS    := {}

		//Despreza quando demitido sem movimento
		If !empty(TRB->RA_DEMISSA) .and. left(TRB->RA_DEMISSA,6) < MV_PAR02
			lTemValor := .f.
			For nTr:= 1 to len(aconven[nxConv,6])
				If TSRDC->&(aconven[nxConv,6,nTr,1]) > 0
					lTemValor := .t.
					Exit
				EndIf
			Next nTr
		EndIf			
			 
		If lTemValor			

                nxtam:= len(aconven[nxConv,6])+8
                
				For nxColx:= 1 to len(aConven[nxConv,6]) + 27 
					aAdd(aDados, "" )
				Next
							
				//abro a tabela de verbas para buscar a coluna correspondente.
				nTotal := 0 
				cxDeta := ""
				For nTr:= 1 to len(aconven[nxConv,6])   
				
					// preenche valor na coluna
					cxDeta := round(TSRDC->&(aconven[nxConv,6,nTr,1]),2)  
					
					// a partir da posicao 9 comeca a impressao dos grupos 
					aDados[8+nTr]:= cxDeta	   
					
					// aglutinando totalizadores de coluna
					axTot[8+nTr]+= cxDeta									
					
					// verifica se é total e armazena em campo separado
					nTotal := 0
					if (alltrim( aconven[nxConv,6,nTr,2] ) = "TOTAL")
						For nCont := 1 to nTr
							nTotal += round(TSRDC->&(aconven[nxConv,6,nCont,1]),2)
						next
						// seta o valor total do funcionario na ultima coluna
						aDados[len(aConven[nxConv,6]) + 8 ]  := nTotal
                        
      					// aglutinando totalizadores de coluna
						axTot[len(aConven[nxConv,6]) + 8 ]  += nTotal  
						
						// informacoes utilizadas no totalizador final
						cxCabTot:= aConven[nxConv,4]
						nPos:= 0
				 		If !(nPos := Ascan(aTotais,{|x| x[1] == "Individual" .And. x[2] == cxCabTot })) > 0
					 		aAdd(aTotais, { "Individual", cxCabTot, nxFunc+= 1, nTotal, nAcresc, nDescon} ) 			
				 		Else                                                                        
					 		aTotais[nPos,3]+= 1
					 		aTotais[nPos,4]+= nTotal
				 		Endif   
				 		
						
					Else									
						// totalizando a coluna SUbTotal
						nxSubTot += round(TSRDC->&(aconven[nxConv,6,nTr,1]),2)
						
						If "SUB" $  aconven[nxConv,6,nTr,1] 
							cxDeta := nxSubTot 
						 	axTot[8+nTr]+= nxSubTot
						Endif 
						
					EndIf

				
				Next 
			    
			    //seta informacoes nas posicoes fixas. 
			   	aDados[1] := SUBSTR(TRB->RA_CC,2,4) + " - " + TRB->ZZC_RAZAO+space(40)
				aDados[2] := SUBSTR(TRB->RA_CC,6,4) + " - " + TRB->ZZF_DESCR
				aDados[3]:= TRANSFORM( TRB->ZZF_CNPJ, "@R 99.999.999/9999-99" )
				aDados[4]:= TRB->RA_MAT 
				aDados[5]:= TRB->RA_NOME 
				aDados[6]:= DTOC( STOD( TRB->RA_ADMISSA ) ) 
				aDados[7]:= if(left(TRB->RA_DEMISSA,6) > MV_PAR02,dtoc(ctod("//")),DTOC( STOD( TRB->RA_DEMISSA ) ))// //aConven[nxConv,5]
				cxSitFol := ''	
				If (nPos := Ascan(aSit,{|x| x[1] == alltrim(TRB->RA_SITFOLH) })) > 0
					cxSitFol := aSit[nPos,2]
				Endif
				aDados[8] := cxSitFol
                // imprime os dados apos os valores
				aDados[nxtam+1]:= ""   
				aDados[nxtam+2]:= if(!empty(TRB->ZZF_MO),TRB->ZZF_MO,TRB->ZZC_MO)
				If (nPos := Ascan(aMO,{|x| x[1] == alltrim( if(!empty(TRB->ZZF_MO),TRB->ZZF_MO,TRB->ZZC_MO) ) })) > 0
					aDados[nxtam+3] := aMO[nPos,2]
				Endif
				aDados[nxtam+4]:= TRB->ZZC_DESCR
				aDados[nxtam+5]:= TRB->ZZF_ENDERE 
				aDados[nxtam+6]:= TRB->ZZF_UF				
				aDados[nxtam+7]:= TRB->ZZF_BAIRRO												  				
				cxSMunic := ''	
				If (nPos := Ascan(aMuni,{|x| x[1] == TRB->ZZF_UF .And. x[2] == TRB->ZZF_CODMUN })) > 0
					cxSMunic := aMuni[nPos,3]
				Endif   
				aDados[nxtam+8]:= cxSMunic
				aDados[nxtam+9]:= TRB->ZZF_TELEF 
				aDados[nxtam+10]:= TRB->ZZF_EMAILR
				aDados[nxtam+11]:= TRB->RA_CC
				aDados[nxtam+12]:= TRB->RA_SALARIO     
				aDados[nxtam+13]:= TRB->RA_HRSMES 
				aDados[nxtam+14]:= TRANSFORM( TRB->RA_CIC, "@R 999.999.999-99" )				
				aDados[nxtam+15]:= if(empty(TRB->ZZF_NUMCON),TRB->ZZC_NUMCON,TRB->ZZF_NUMCON) 
				aDados[nxtam+16]:= TRB->RA_XSETOR
				aDados[nxtam+17]:= TRB->ZZI_DESCR
				aDados[nxtam+18]:= DTOC( STOD( TRB->RA_DTFIMCT ) )
				aDados[nxtam+19]:= TRB->ZRA_CODSOC
				
				// cria a linha oExcel					      
				oExcel:AddRow(cTipo,cResName,aDados)
				
				IF lTxtSoe
					aadd(aTxtSoe,{TRB->RA_CIC,TRB->RA_FILIAL,TRB->RA_MAT})
				endif
								
				nContRegs++
				nContTotal++

				// clona dados do array
				aAdd(aBkpDds,aClone(aDados))

		EndIf

		TSRDC->( dbSkip() )	               
	EndDo                         			
	
	If Select("TSRDC") <> 0 
		DbSelectArea("TSRDC")
		DbCloseArea()
	Endif   			

 TRB->( dbSkip() )
	
EndDo   

If nContRegs > 0 
	axTot[1]:= "Total de Funcionarios - " + cvaltochar(nContRegs)
	// cria a linha Totalizador no excel					      
	oExcel:AddRow(cTipo,cResName,axTot) 
Endif		
		

// fecho as tabelas
If Select("TRB") <> 0 
	DbSelectArea("TRB")
	DbCloseArea()
Endif  

If Select("TZZH") <> 0 
	DbSelectArea("TZZH")
	DbCloseArea()
Endif    

//Se ja existe PDF com o mesmo nome 
If File(cArquivo)

	//Deleta o PDF anterior
	If !(fErase(cArquivo) == 0)
		cMsg := '   Ocorreram problemas na tentativa de deleção do arquivo '+AllTrim(cArquivo)+'.'+CRLF+'Esse arquivo continuará com o conteúdo anterior.'
		MsgStop(cMsg)
		aadd(aLog,cMsg)
		fWrite(nHdlLog, aLog[len(aLog)] + CRLF)
		Return //Exit
	EndIf

EndIf 

oExcel:Activate()

IF lTxtSoe
	cArquivo:= LEFT(cArquivo,LEN(cArquivo)-4)+".txt"
	GTXTSOE(oExcel,cArquivo,aTxtSoe)
ELSE
	oExcel:GetXMLFile(cArquivo)
ENDIF
	
/*
oExcel:DeActivate()

oMsExcel := MsExcel():New()
oMsExcel:WorkBooks:Open(cArquivo)
oMsExcel:SetVisible(.T.)
oMsExcel := oMsExcel:Destroy()
	
FreeObj(oExcel)
*/
oExcel := NIL  

If nContRegs > 0
	nPos := len(aTotais)
	aadd(aLog,"   "+padr(cArquivo,90)+padr(aTotais[nPos,1],12)+If('Indiv'$aTotais[nPos,1],space(15),aTotais[nPos,2])+"  Func:  "+strzero(aTotais[nPos,3],4)+"   Valor: "+Transform( aTotais[nPos,4]+aTotais[nPos,5]-aTotais[nPos,6], '@E 99,999,999.99')) 
	fWrite(nHdlLog, aLog[len(aLog)] + CRLF)
	If !file(cArquivo)
		aadd(aLog,"***"+padr(cArquivo,90)+" *** NAO GERADO POR TIMEOUT DE REDE ***") 
		fWrite(nHdlLog, aLog[len(aLog)] + CRLF)
	EndIf  
Endif

// Chamar função para replicar dados no BackOffice
FwMsgRun(, {||U_xLinkBac(aBkpDds,MV_PAR02) },"Conexão","Gerando dados no BackOffice...")

//If nHdlLog > 0 
//	fClose(nHdlLog)
//Endif	
		
Return

/*/{Protheus.doc} GTXTSOE
Rotina de geração do TXT SOE
@author carlos.henrique
@since 05/12/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
static function GTXTSOE(oExcel,cArquivo,aTxtSoe)
Local cLinTxt:= ""
Local nCnta	 := 0
Local nCntb	 := 0
Local aLin   := {}
Local cCpf	 := ""
Local nValPg := 0
Local nProv13:= 0
Local nProFer:= 0
Local nValCi := 0
Local cCodMot:= ""
Local cDesMot:= ""


FERASE(cArquivo)

nHandle := MsfCreate(cArquivo,0)

DBSELECTAREA("SRA")
SRA->(DBSETORDER(5))

For nCnta:= 1 to len(oExcel:aTable[1][4])-1     
	aLin:= ACLONE(oExcel:aTable[1][4][nCnta])
	
	cCpf	:= AllTrim(STRTRAN(STRTRAN(STRTRAN(aLin[43],"-",""),"/",""),".",""))
	nValPg 	:= aLin[29]-aLin[27]
	nProv13 := aLin[25]
	nProFer := aLin[26]
	nValCi  := aLin[27]
	cCodMot := ""
	cDesMot := ""
	
	IF (nPosCpf:= ASCAN(aTxtSoe,{|x| x[1]==cCpf })) >0
		cFilRA:= aTxtSoe[nPosCpf][2]
		cMatRA:= aTxtSoe[nPosCpf][3]
	ENDIF	
	
	PosConv(TRIM(aLin[40]))
	PosSRA(cCpf,cFilRA,cMatRA)
	
	If !Empty(SRA->RA_DEMISSA) 
		SRG->(DbSetOrder(01))  //rg_filial+mat
		If SRG->(DbSeek(SRA->RA_FILIAL+SRA->RA_MAT))  //"RG_FILIAL+RG_MAT+DTOS(RG_DTGERAR)"
			cCodMot :=  SRG->RG_TIPORES
		Endif
		RCC->(DbSetOrder(1))  //RCC_FILIAL+RCC_CODIGO+RCC_FIL+RCC_CHAVE+RCC_SEQUEN
		RCC->(DbSeek(XFilial("RCC")+"S043"))
		While RCC->(!EOF()) .and. RCC->RCC_FILIAL == XFilial("RCC")  .AND. RCC->RCC_CODIGO == "S043"
			If SubsTr(RCC->RCC_CONTEU,1,2) == SRG->RG_TIPORES
				cDesMot :=  AllTrim(SubsTr(RCC->RCC_CONTEU,3,Len(RCC->RCC_CONTEU)-2))
				Exit
			Endif 
			RCC->(DbSkip())
		Enddo
	else
		cCodMot :=  "0"
		cDesMot :=  "Nenhum"
	Endif
	
	cLinTxt := AllTrim(STRTRAN(STRTRAN(STRTRAN(aLin[3],"-",""),"/",""),".",""))+"|"  	//CNPJ
 	cLinTxt += AllTrim(ZZC->ZZC_RAZAO)+"|"   											//Razao Social    
 	cLinTxt += STRZERO(VAL(ZZF->ZZF_ITBKO),5)+"|" 										//Item contabil
 	cLinTxt += AllTrim(Transform(nValCi,'@E 99,999,999.99'))+"|"     					//Valor da Contribuição institucional CI
 	cLinTxt += cCpf+"|" 																//CPF do Aprendiz
 	cLinTxt += Alltrim(SRA->RA_NOME)+"|"												//Nome do Aprendiz
 	cLinTxt += If(Empty(SRA->RA_MAT),"",StrZero(Val(SRA->RA_MAT),6))+"|"				//Matricula do Aprendiz
 	cLinTxt += AllTrim(Transform(nValPg, '@E 99,999,999.99'))+"|"						//Valor Pago R$ (Total ressarcimento CI)
 	cLinTxt += "0"+"|" 																	//Tratamento Especial (0/1) informado fixo 0
 	cLinTxt += AllTrim(ZZF->ZZF_NUMCON)+"|"	   											//Código do Convenio (SOC/SOE) verificar se esta vazio
 	cLinTxt += AllTrim(Transform(nProv13 ,'@E 99,999,999.99'))+"|"  					//Valor da provisão 13. salario R$	
 	cLinTxt += AllTrim(Transform(nProFer,'@E 99,999,999.99'))+"|" 						//Valor da provisão Ferias R$ 
 	cLinTxt += If(Empty(SRA->RA_DEMISSA),"",DTOC(SRA->RA_DEMISSA))+"|"					//Data da recisao)
 	cLinTxt += AllTrim(cCodMot)+"|"														//Código Motivo da Recisao RG_TIPORES
 	cLinTxt += AllTrim(cDesMot) + CRLF													//Descricao motivo da Recisao 
 	
 	fWrite(nHandle, cLinTxt)
 		
next 

FClose(nHandle)   

return                   
/*/{Protheus.doc} PosConv
Posiciona convenente
@author carlos.henrique
@since 05/12/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static function PosConv(cCodAux)
Local cTab   := GetNextAlias()
Local cConven:= RIGHT(cCodAux,LEN(cCodAux)-1)   

DBSELECTAREA("ZZC")
ZZC->(DBSETORDER(1))
ZZC->(DBSEEK(XFILIAL("ZZC")+ LEFT(cConven,4) ))

DBSELECTAREA("ZZD")
ZZD->(DBSETORDER(1))
ZZD->(DBSEEK(XFILIAL("ZZD")+ LEFT(cConven,4) ))

DBSELECTAREA("ZZF")
	
BeginSql Alias cTab
	SELECT R_E_C_N_O_ AS RECZZF FROM %TABLE:ZZF% ZZF
	WHERE ZZF_FILIAL=%XFILIAL:ZZF%
	AND ZZF_CODCON+ZZF_CODIGO=%EXP:cConven%
	AND ZZF.D_E_L_E_T_=''
EndSql

//GETLastQuery()[2]	

(cTab)->(dbSelectArea((cTab)))                    
(cTab)->(dbGoTop())  	
IF (cTab)->(!EOF())
	ZZF->(DBGOTO((cTab)->RECZZF))
ENDIF      

(cTab)->(dbCloseArea())	 

Return  	
/*/{Protheus.doc} PosSRA
Posiciona SRA
@author carlos.henrique
@since 05/12/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static function PosSRA(cCpf,cFilRA,cMatRA)
Local cTab:= GetNextAlias()

DBSELECTAREA("SRA")
	
IF !EMPTY(cFilRA)
	BeginSql Alias cTab
		SELECT R_E_C_N_O_ AS RECSRA FROM %TABLE:SRA% SRA
		WHERE RA_FILIAL=%EXP:cFilRA% 
		AND RA_MAT=%EXP:cMatRA%
		AND SRA.D_E_L_E_T_=''
	EndSql
ELSE	
	BeginSql Alias cTab
		SELECT R_E_C_N_O_ AS RECSRA FROM %TABLE:SRA% SRA
		WHERE RA_CIC=%EXP:cCpf%
		AND SRA.D_E_L_E_T_=''
	EndSql
ENDIF

//GETLastQuery()[2]	

(cTab)->(dbSelectArea((cTab)))                    
(cTab)->(dbGoTop())  	
IF (cTab)->(!EOF())
	SRA->(DBGOTO((cTab)->RECSRA))
ENDIF      

(cTab)->(dbCloseArea())	 

Return  

User Function xLinkBac(aBkpDds,MV_PAR02)

	Local nx
	Local clog	  := ""
	Local nHndERP := AdvConnection()
	Local cBcoBk  := "MSSQL/CDPRXC_HOM" //Alltrim(SuperGetMv("CI_BANCOBK",.F.,"MSSQL/CDPRXC_HOM"))
	Local cSrvBk  := "172.28.13.135" //Alltrim(SuperGetMv("CI_SERVIBK",.F.,"172.28.13.135"))
	Local nPtaBk  := 9335 //SuperGetMv("CI_PORTABK",.F.,9335)
	Local cTbBk	  := Iif(cEmpAnt=="40","ZCE010","ZCE030")
	Local lInsert := .T.
	Local nVlrCI  := 0    //Valor Contribuição institucional
	Local nVlrTRCI := 0   //Valor Pago Total Ressarcimento CI 
	Local nVlrP13 := 0    //Valor Provisão 13°
	Local nVlrPFer := 0   //Valor Provisão Férias
	Local BackMVPAR02 := MV_PAR02 //Guarda o formato AAAAMM

	MV_PAR02 := SUBSTR(MV_PAR02,5,2)+SUBSTR(MV_PAR02,1,4) //altera para o formato MMAAAA

	// Abre conexão com BackOffice
	nConBk := TCLink(cBcoBk,cSrvBk,nPtaBk)
	
	If nConBk >= 0
		
		// Seta TOP do BackOffice
		TCSetConn(nConBk)
		
		For nx := 1 to Len(aBkpDds)

			if _TpArqSaida = 4
				nVlrCI   := aBkpDds[nx][27]  
				nVlrTRCI := (aBkpDds[nx][29] - aBkpDds[nx][27])     
				nVlrP13  := aBkpDds[nx][25]   
				nVlrPFer := aBkpDds[nx][26]    
			else
				nVlrCI   := 0   
				nVlrTRCI := 0    
				nVlrP13  := 0    
				nVlrPFer := 0  
			endif 

			lInsert := .T.
			cQry := " SELECT * FROM "+cTbBk;
					+ " WHERE ZCE_PERIOD = '"+MV_PAR02+"' ";
					+ " AND   ZCE_CC 	 = '"+aBkpDds[nx][40]+"' ";
					+ " AND   ZCE_MAT	 = '"+aBkpDds[nx][04]+"' ";
					+ " AND   D_E_L_E_T_='' "
			DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TRAZCE",.F.,.T.)
			If TRAZCE->(!Eof())

				lInsert := .F.
				If TRAZCE->ZCE_FATURA == "2"

					cQry := " UPDATE "+cTbBk
					cQry += " SET ZCE_RAZAO = '"+Substr(Alltrim(aBkpDds[nx][01]),8,140)+"' "
					If !Empty(aBkpDds[nx][02])
						cQry += ", ZCE_DESCRI = '"+Substr(Alltrim(aBkpDds[nx][02]),8,20)+"' "
					EndIf
					If !Empty(aBkpDds[nx][03])
						cQry += ", ZCE_CNPJ = '"+StrTran(StrTran(StrTran(Alltrim(aBkpDds[nx][03]),".",""),"/",""),"-","")+"' "
					EndIf
					If !Empty(aBkpDds[nx][34])
						cQry += ", ZCE_ENDERE = '"+Alltrim(aBkpDds[nx][34])+"' "
					EndIf
					If !Empty(aBkpDds[nx][38])
						cQry += ", ZCE_TELEFO = '"+Alltrim(aBkpDds[nx][38])+"' "
					EndIf
					If !Empty(aBkpDds[nx][39])
						cQry += ", ZCE_EMAIL = '"+Alltrim(aBkpDds[nx][39])+"' "
					EndIf
					If !Empty(aBkpDds[nx][31])
						cQry += ", ZCE_IDMO = '"+Alltrim(aBkpDds[nx][31])+"' "
					EndIf
					If !Empty(aBkpDds[nx][32])
						cQry += ", ZCE_MO = '"+Alltrim(aBkpDds[nx][32])+"' "
					EndIf
					If !Empty(aBkpDds[nx][35])
						cQry += ", ZCE_UF = '"+Alltrim(aBkpDds[nx][35])+"' "
					EndIf
					If !Empty(aBkpDds[nx][36])
						cQry += ", ZCE_BAIRRO = '"+Alltrim(aBkpDds[nx][36])+"' "
					EndIf
					If !Empty(aBkpDds[nx][37])
						cQry += ", ZCE_MUN = '"+Alltrim(aBkpDds[nx][37])+"' "
					EndIf
					If !Empty(aBkpDds[nx][05])
						cQry += ", ZCE_NOME = '"+Alltrim(aBkpDds[nx][05])+"' "
					EndIf
					If !Empty(aBkpDds[nx][06])
						cQry += ", ZCE_ADMISS = '"+DtoS(StoD(aBkpDds[nx][06]))+"' "
					EndIf
					If !Empty(aBkpDds[nx][07])
						cQry += ", ZCE_DEMISS = '"+DtoS(StoD(aBkpDds[nx][07]))+"' "
					EndIf
					If !Empty(aBkpDds[nx][09])
						cQry += ", ZCE_SALARI = '"+cValtoChar(aBkpDds[nx][09])+"' "
					EndIf
					If !Empty(aBkpDds[nx][42])
						cQry += ", ZCE_HRSMES = '"+cValtoChar(aBkpDds[nx][42])+"' "
					EndIf
					If !Empty(aBkpDds[nx][08])
						cQry += ", ZCE_SITFOL = '"+Iif(Alltrim(aBkpDds[nx][08])=="FERIAS","F",Iif(Alltrim(aBkpDds[nx][08])=="DEMITIDO","D",Iif(Alltrim(aBkpDds[nx][08])=="TRANSFERIDO","T",Iif(Alltrim(aBkpDds[nx][08])=="AFASTADO TEMP.","A",""))))+"' "
					EndIf
					If !Empty(aBkpDds[nx][43])
						cQry += ", ZCE_CPF = '"+StrTran(StrTran(Alltrim(aBkpDds[nx][43]),".",""),"-","")+"' "
					EndIf
					If !Empty(aBkpDds[nx][47])
						cQry += ", ZCE_DTFCTR = '"+DtoS(StoD(aBkpDds[nx][47]))+"' "
					EndIf
					If !Empty(aBkpDds[nx][48])
						cQry += ", ZCE_IDESTU = '"+Alltrim(aBkpDds[nx][48])+"' "
					EndIf
					if _TpArqSaida = 4 //somente nesta opção estes campos são populados
						cQry += ", ZCE_VLCI = '"+ALLTRIM(STR(nVlrCI))+"' "
						cQry += ", ZCE_VLTRCI = '"+ALLTRIM(STR(nVlrTRCI))+"' "
						cQry += ", ZCE_VLP13 = '"+ALLTRIM(STR(nVlrP13))+"' "
						cQry += ", ZCE_VLPFER = '"+ALLTRIM(STR(nVlrPFer))+"' "
					endif
					cQry += " WHERE ZCE_PERIOD = '"+MV_PAR02+"' ";
							+ " AND   ZCE_CC 	 = '"+aBkpDds[nx][40]+"' ";
							+ " AND   ZCE_MAT	 = '"+aBkpDds[nx][04]+"' ";
							+ " AND   D_E_L_E_T_='' "

					If TCSQLEXEC(cQry) < 0
						clog += "Erro: " + TCSQLError() + CRLF 
					Else
						clog += cQry + CRLF
					EndIf

				EndIf
				DbSkip()

			EndIf

			If lInsert

				cQry := " DECLARE @RECNO INT "
     			cQry += " SET @RECNO = ISNULL((SELECT MAX("+cTbBk+".R_E_C_N_O_)+1 FROM "+cTbBk+"),1) "
				cQry += " INSERT INTO "+cTbBk+" (ZCE_FILIAL,ZCE_PERIOD,ZCE_RAZAO,ZCE_DESCRI,ZCE_CNPJ,ZCE_ENDERE,ZCE_TELEFO,"+;
						" ZCE_EMAIL,ZCE_IDMO,ZCE_MO,ZCE_UF,ZCE_BAIRRO,ZCE_MUN,ZCE_MAT,ZCE_NOME,ZCE_ADMISS,ZCE_DEMISS,"+;
						" ZCE_CC,ZCE_SALARI,ZCE_HRSMES,ZCE_SITFOL,ZCE_CPF,ZCE_FATURA,ZCE_VLCI,ZCE_VLTRCI,ZCE_VLP13,ZCE_VLPFER,ZCE_DTFCTR,ZCE_IDESTU,R_E_C_N_O_) "+;
						" VALUES (' ','"+MV_PAR02+"','"+;
									Substr(Alltrim(aBkpDds[nx][01]),8,140)+"','"+;
									Substr(Alltrim(aBkpDds[nx][02]),8,20)+"','"+;
									StrTran(StrTran(StrTran(Alltrim(aBkpDds[nx][03]),".",""),"/",""),"-","")+"','"+;
									Alltrim(aBkpDds[nx][34])+"','"+;
									Alltrim(aBkpDds[nx][38])+"','"+;
									Alltrim(aBkpDds[nx][39])+"','"+;
									Alltrim(aBkpDds[nx][31])+"','"+;
									Alltrim(aBkpDds[nx][32])+"','"+;
									Alltrim(aBkpDds[nx][35])+"','"+;
									Alltrim(aBkpDds[nx][36])+"','"+;
									Alltrim(aBkpDds[nx][37])+"','"+;
									Alltrim(aBkpDds[nx][04])+"','"+;
									Alltrim(aBkpDds[nx][05])+"','"+;
									DtoS(StoD(aBkpDds[nx][06]))+"','"+;
									DtoS(StoD(aBkpDds[nx][07]))+"','"+;
									Alltrim(aBkpDds[nx][40])+"',"+;
									cValtoChar(aBkpDds[nx][09])+","+;
									cValtoChar(aBkpDds[nx][42])+",'"+;
									Iif(Alltrim(aBkpDds[nx][08])=="FERIAS","F",Iif(Alltrim(aBkpDds[nx][08])=="DEMITIDO","D",Iif(Alltrim(aBkpDds[nx][08])=="TRANSFERIDO","T",Iif(Alltrim(aBkpDds[nx][08])=="AFASTADO TEMP.","A",""))))+"','"+;
									StrTran(StrTran(Alltrim(aBkpDds[nx][43]),".",""),"-","")+;
									"','2','"+alltrim(str(nVlrCI))+"','"+alltrim(str(nVlrTRCI))+"','"+alltrim(str(nVlrP13))+"','"+alltrim(str(nVlrPFer))+"','"+DtoS(StoD(aBkpDds[nx][47]))+"','"+alltrim(aBkpDds[nx][48])+"',@RECNO)"					
			
				If TCSQLEXEC(cQry) < 0
					clog += "Erro: " + TCSQLError() + CRLF 
				Else
					clog += cQry + CRLF
				EndIf

			EndIf
			DBCloseArea()

		Next nx
		
		// Atualiza as definições do BackOffice
		TCRefresh(cTbBk)
		// Fecha a conexão com BackOffice
		TCUnLink(nConBk)

	EndIf

	memowrite("C:\temp\ciee.txt",clog)
	
	//Seta TOP de RH
	TCSetConn(nHndERP)

	MV_PAR02 := BackMVPAR02 //Retorna para o formato AAAAMM

Return
