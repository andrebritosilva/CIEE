#Include "PROTHEUS.CH" 
#Include "GPER050.CH"   
#Include "REPORT.CH"
#Include "RPTDEF.CH"
#Include "FWPrintSetup.ch"

#DEFINE nRA_FILIAL 	1
#DEFINE nRA_CC     	2
#DEFINE nRA_MAT		3
#DEFINE nRA_NOME	4 

#DEFINE nNFL_LCR_BS 1
#DEFINE nNFL_LCR_IR 2
#DEFINE nNADIAN_BS 	3
#DEFINE nNADIAN_IR 	4
#DEFINE nNFER_BS   	5
#DEFINE nNFER_IR   	6
#DEFINE nN13SAL_BS 	7
#DEFINE nN13SAL_IR 	8
#DEFINE nNPLR_BS   	9
#DEFINE nNPLR_IR   	10
#DEFINE nNTOTAIS_BS 11
#DEFINE nNTOTAIS_IR 12

Static nTpImpre := 0
Static aOrdCab
Static aOrdDet


User Function CFINR085(cNomeDarf,cDarfDir, lRelatorio)

Local aArea			 := GetArea()
Local cTmpPath       := GetTempPath()
Private cNomeRel     := cNomeDarf
Private cDirRel      := cDarfDir
Private cPerg   	 := ''
Private oReport   	 := Nil
Private cDesc1		 := OemToAnsi(STR0039) + " " + OemToAnsi(STR0002) + " " + OemToAnsi(STR0003)//"Dirf Mensal" ### "Ser  impresso de acordo com os parametros solicitados pelo"  ### "usu rio."
Private cTit    	 := OemToAnsi(STR0011)			//"RELATORIO DIRF MENSAL"                                                         

Private wnrel     := "GPER050"            //Nome Default do relatorio em Disco
Private lIRMesAnt := .T.

Default lRelatorio :=  .T.

If lRelatorio
	fRadioPerg(@nTpImpre, @cPerg)
Else
	nTpImpre := 2
EndIf

SetMnemonicos(NIL,NIL,.T.)

If nTpImpre == 1
	cPerg := 'GP050R'
	Pergunte(cPerg, .F.)
	oReport := ReportDef(cPerg)
	oReport:PrintDialog()
Else
	cPerg := 'GPR050'
	Pergunte(cPerg, .F.)
	If Empty(Mv_Par13)
		Pergunte(cPerg, .T.)
	EndIf 	
	GR050Imp(1, .F., WnRel, "SRA", "1", oReport, "GPER050")
EndIf

If lRelatorio
	FERASE(cTmpPath + "DARF_APURACAO_IR_BOLSA_AUXILIO" + ".pdf") 
	CpyS2T(cDirRel + cNomeRel + ".pdf" , cTmpPath , .F. )
	
	If File(cTmpPath+cNomeRel+".pdf")
		ShellExecute("OPEN",cTmpPath+cNomeRel+".pdf","","",5)
	Else
		MSGALERT("Não foi possível realizar a cópia do relatório para o diretório:" + CRLF + cTmpPath)
	EndIf
EndIf

RestArea( aArea )

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ ReportDef  ³ Autor ³ Tania Bronzeri        ³ Data ³13/06/2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Relatorio de Imposto de Renda / DIRF                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ GPER050(void)                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³                                                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ GPER050 - Generico - Release 4                               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/

Static Function ReportDef(cPerg)

Local oSection1 := Nil
Local oSecCab   := Nil
//Local oCell	    := Nil
Local cTitulo	:= OemToAnsi(STR0011) //"RELATORIO DIRF MENSAL"
Local nTamSRA   := 2 //Utilizada para nColSpace (Tamanho da Matrícula)

// Criacao do componente de impressao
DEFINE REPORT oReport NAME "GPER050" TITLE cTitulo PARAMETER cPerg ACTION {|oReport| R050Imp(oReport)} DESCRIPTION OemtoAnsi(STR0022) //"RELATORIO DIRF MENSAL" ### "Emite Relacao do Imposto de Renda - Dirf Mensal." 
oReport:SetTotalInLine(.F.)

Pergunte("GP050R",.F.)

//                     New(oParent, cTitle            , uTable , aOrder                                                    ,  lLoadCells    , lLoadOrder    , uTotalText    , lTotalInLine    , lHeaderPage    , lHeaderBreak    , lPageBreak    , lLineBreak    , nLeftMargin     , lLineStyle          , nColSpace    , lAutoSize       , cCharSeparator       , nLinesBefore    , nCols    , nClrBack    , nClrFore    , nPercentage    )
oSecCab := TRSection():New(oReport, OemToAnsi(STR0001), {"SRA"}, {OemToAnsi(STR0004),OemToAnsi(STR0005),OemToAnsi(STR0006)},  /*lLoadCells*/, /*lLoadOrder*/, /*uTotalText*/, /*lTotalInLine*/, /*lHeaderPage*/, /*lHeaderBreak*/, /*lPageBreak*/, /*lLineBreak*/, 0/*nLeftMargin*/, .F./*lLineStyle*/   , /*nColSpace*/, .F./*lAutoSize*/, "|"/*cCharSeparator*/, 50/*nLinesBefore*/, /*nCols*/, /*nClrBack*/, /*nClrFore*/, /*nPercentage*/) // "Contribuicoes" ### "Matr¡cula" ### "Centro de Custo" ### "Nome"
oSecCab:SetTotalInLine(.F.)
oSecCab:SetLinesBefore(0)

TRCell():New(oSecCab, "RA_FILIAL"  , "SRA" , OemToAnsi(Alltrim(STR0023)), /*Picture*/			, /*Tamanho*/, /*lPixel*/   , /*{|| code-block de impressao }*/ 										    , "LEFT"	,  	.F.			,"LEFT"		    ,				,				,.F.	  , /*12632256*/   	,				,			)
TRCell():New(oSecCab, "RA_CC"      , "SRA" , OemToAnsi(Alltrim(STR0024)), /*Picture*/			, /*Tamanho*/, /*lPixel*/   , /*{|| code-block de impressao }*/ 										    , "LEFT"	,	.F.			,"LEFT"		    ,				,				,.F.	  , /*32768*/        ,				,			)
TRCell():New(oSecCab, "RA_MAT"     , "SRA" , OemToAnsi(Alltrim(STR0025)), /*Picture*/			, /*Tamanho*/, /*lPixel*/   , /*{|| code-block de impressao }*/ 										    , "LEFT"	,	.F.			,"LEFT"		    ,				,nTamSRA      ,.F.	  , /*12632256*/     ,				,			)
TRCell():New(oSecCab, "RA_NOME"    , "SRA" , /*Titulo Coluna*/          , /*Picture*/			, /*Tamanho*/, /*lPixel*/   , /*{|| code-block de impressao }*/										    , "LEFT"	,	.F.			,"LEFT"		    ,				,				,.F.	  , /*32768*/	       ,				,			)

oSection1 := TRSection():New(oReport, OemToAnsi(STR0001), {}, {OemToAnsi(STR0004),OemToAnsi(STR0005),OemToAnsi(STR0006)}, /*lLoadCells*/, /*lLoadOrder*/, /*uTotalText*/, /*lTotalInLine*/, /*lHeaderPage*/, /*lHeaderBreak*/, /*lPageBreak*/, /*lLineBreak*/, 0/*nLeftMargin*/, .F./*lLineStyle*/   , /*nColSpace*/, .F./*lAutoSize*/, "|"/*cCharSeparator*/, /*nLinesBefore*/, /*nCols*/, /*nClrBack*/, /*nClrFore*/, /*nPercentage*/) // "Contribuicoes" ### "Matr¡cula" ### "Centro de Custo" ### "Nome"
oSection1:SetTotalInLine(.F.)
oSection1:SetLinesBefore(0)

TRCell():New(oSection1, "NFL_LCR_BS" , "  "  , OemToAnsi(Alltrim(STR0060)), "@E 999,999,999.99" , 14         , /*lPixel*/   , {|| aFolBas[_nTipo] }                                                                        , "RIGHT" ,   .F.      ,"RIGHT"       ,           ,          ,.F.       , /*12632256*/ ,         ,      )
TRCell():New(oSection1, "NFL_LCR_IR" , "  "  , OemToAnsi(Alltrim(STR0061)), "@E   9,999,999.99" , 12         , /*lPixel*/   , {|| aFolIR [_nTipo] }                                                                        , "RIGHT" ,   .F.      ,"RIGHT"       ,           ,          ,.F.       , /*32768*/    ,         ,      )
TRCell():New(oSection1, "NADIAN_BS"  , "  "  , OemToAnsi(Alltrim(STR0028)), "@E 999,999,999.99" , 14         , /*lPixel*/   , {|| aAdiBas[_nTipo] }                                                                        , "RIGHT" ,   .F.      ,"RIGHT"       ,           ,          ,.F.       , /*12632256*/ ,         ,      )
TRCell():New(oSection1, "NADIAN_IR"  , "  "  , OemToAnsi(Alltrim(STR0029)), "@E   9,999,999.99" , 12         , /*lPixel*/   , {|| aAdiIR [_nTipo] } /*{|| code-block de impressao }*/                                      , "RIGHT" ,   .F.      ,"RIGHT"       ,           ,          ,.F.       , /*32768*/    ,         ,      )
TRCell():New(oSection1, "NFER_BS"    , "  "  , OemToAnsi(Alltrim(STR0030)), "@E 999,999,999.99" , 14         , /*lPixel*/   , {|| aFerBas[_nTipo] } /*{|| code-block de impressao }*/                                      , "RIGHT" ,   .F.      ,"RIGHT"       ,           ,          ,.F.       , /*12632256*/ ,         ,      )
TRCell():New(oSection1, "NFER_IR"    , "  "  , OemToAnsi(Alltrim(STR0031)), "@E   9,999,999.99" , 12         , /*lPixel*/   , {|| aFerIR [_nTipo] } /*{|| code-block de impressao }*/                                      , "RIGHT" ,   .F.      ,"RIGHT"       ,           ,          ,.F.       , /*32768*/    ,         ,      )
TRCell():New(oSection1, "N13SAL_BS"  , "  "  , OemToAnsi(Alltrim(STR0032)), "@E 999,999,999.99" , 14         , /*lPixel*/   , {|| a13Bas [_nTipo] } /*{|| code-block de impressao }*/                                      , "RIGHT" ,   .F.      ,"RIGHT"       ,           ,          ,.F.       , /*12632256*/ ,         ,      )
TRCell():New(oSection1, "N13SAL_IR"  , "  "  , OemToAnsi(Alltrim(STR0033)), "@E   9,999,999.99" , 12         , /*lPixel*/   , {|| a13IR  [_nTipo] } /*{|| code-block de impressao }*/                                      , "RIGHT" ,   .F.      ,"RIGHT"       ,           ,          ,.F.       , /*32768*/    ,         ,      )
TRCell():New(oSection1, "NPLR_BS"    , "  "  , OemToAnsi(Alltrim(STR0056)), "@E 999,999,999.99" , 14         , /*lPixel*/   , {|| aPLRBas[_nTipo] } /*{|| code-block de impressao }*/                                      , "RIGHT" ,   .F.      ,"RIGHT"       ,           ,          ,.F.       , /*12632256*/ ,         ,      )
TRCell():New(oSection1, "NPLR_IR"    , "  "  , OemToAnsi(Alltrim(STR0057)), "@E   9,999,999.99" , 12         , /*lPixel*/   , {|| aPLRIR [_nTipo] } /*{|| code-block de impressao }*/                                      , "RIGHT" ,   .F.      ,"RIGHT"       ,           ,          ,.F.       , /*32768*/    ,         ,      )
TRCell():New(oSection1, "NTOTAIS_BS" , "  "  , OemToAnsi(Alltrim(STR0034)), "@E 999,999,999.99" , 14         , /*lPixel*/   , {|| aFolBas[_nTipo] + aAdiBas[_nTipo] + aFerBas[_nTipo] + a13Bas[_nTipo] + aPLRBas[_nTipo] } , "RIGHT" ,   .F.      ,"RIGHT"       ,           ,          ,.F.       , /*12632256*/ ,         ,      )
TRCell():New(oSection1, "NTOTAIS_IR" , "  "  , OemToAnsi(Alltrim(STR0035)), "@E 999,999,999.99" , 14         , /*lPixel*/   , {|| aFolIR [_nTipo] + aAdiIR [_nTipo] + aFerIR [_nTipo] + a13IR [_nTipo] + aPLRIR[_nTipo] }  , "RIGHT" ,   .F.      ,"RIGHT"       ,           ,          ,.F.       , /*32768*/    ,         ,      )

Return(oReport)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³GPER050   ºAutor  ³Microsiga           º Data ³  11/09/06   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³                                                            º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/

Static Function R050Imp(oReport)

	GR050Imp(1,.F.,WnRel,"SRA","1",oReport,"GPER050")

Return(Nil)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³GR050Imp  ºAutor  ³Microsiga           º Data ³  01/10/07   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³                                                            º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function GR050Imp(nTipGer, lEnd, WnRel,cString,cAgrupa,oReport,cFonte,lRRA,cTipoRet)

Default lRRA    	:= .F.
Private lTitRRA 	:= lRRA 
Private lPLR 		:= .F. 
Private lGper060 	:= FunName() == "GPER060"

//No caso de impressão em planilha, suprimindo linhas em branco e totais e formato sintético,
//Deixará de suprimir as linhas em branco e totais, caso contrário nada seria impresso/gerado.
If Valtype(oReport) == "O" .ANd. oReport:nDevice == 4 .And. !oReport:lEmptyLineExcel .And. mv_par11 == 2
	oReport:lEmptyLineExcel := .T.
Endif

R050Impressao(nTipGer,lEnd,WnRel,cString,cAgrupa,oReport,cFonte,cTipoRet)

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³GPER050   ºAutor  ³Microsiga           º Data ³  01/10/07   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³                                                            º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function R050Impressao(nTipGer, lEnd, WnRel,cString,cAgrupa,oReport,cFonte,cTipoRet)

Local cFilter 		:= ""

Default cTipoRet    := ""
Default cFonte      := "GPER050"

If !lGper060 .And. Valtype(oReport) == "U"
	oReport     := ReportDef()
	If nTipGer != 2
		Private nOrdem
	EndIf 
Else
	Pergunte("GP050R",.F.)
EndIf

Private cCcDe        	:= mv_par03
Private cCcAte       	:= mv_par04
Private cNomDe       	:= mv_par07
Private cNomAte      	:= mv_par08
Private dDataDe      	:= mv_par09
Private dDataAte     	:= mv_par10
Private cSinAna      	:= Iif(mv_par11 == 1,"A","S")
Private lGeraTitulo  	:= (nTipGer == 2)//Verifica se é geração de título(GPEM650)
Private oBreakFil	    := Nil
Private oBreakCCusto 	:= Nil	
Private cAcessaSRA   	:= &("{ || " + ChkRH("GPER050","SRA","2") + "}")
Private cTitCC	   		:= "" 
Private cTitFil	    	:= ""
Private cTit	       	:= ""
Private cTitulo     	:= ""
Private Titulo	    	:= '' 
Private lGp050Fil    	:= ExistBlock( "GP050FIL" )//variavel p/ PE GP050FIL 
Private lRetPE       	:= .F.//variavel p/ PE GP050FIL
Private aVerba	    	:= {}
Private cVerbaSql		:= ""
Private aPerAberto   	:= {}
Private aPerFechado  	:= {}
Private oSecCab      
Private oSection1    
Private lSalta       := .F. 
Private nTipImp      := IiF(lGeraTitulo, nTipImp, IiF(nTpImpre # Nil, nTpImpre, 1))
Private dVencto      := CtoD('//')
Private cNumRef      := ''
Private cCentra      := ''
Private cSvRet       := ''
Private cOldRet	     := ''
Private aInfo        := {}
Private aCodFol      := {}
Private aCodLido     := {}
Private lRecalcIR    := .F.
Private aFolBas[4] 
Private aAdiBas[4] 
Private aFerBas[4] 
Private a13Bas [4]
Private aFolIR [4]  
Private aAdiIR [4]  
Private aFerIR [4]  
Private a13IR  [4]
Private aPLRBas[4]
Private aPLRIR [4]

Private lImpRelato  := (nTipGer == 1    )  //Na geracao de titulo fincanceiro vem com valor diferente
Private lAgrupFil   := (cAgrupa == "1"  )
Private lAgrupCc    := (cAgrupa $  "2*3")
Private lAgrupFunc  := (cAgrupa == "4"  )
Private aReturn 	:= {STR0007,1,STR0008, 1, 2, 1, "",1 }	// "Zebrado"###"Administra‡„o"
Private nomeprog	:= "GpeR050"
Private aLinha  	:= {}
Private nLastKey 	:= 0

If !lGper060
	oSecCab      := oReport:Section(1)
	oSection1    := oReport:Section(2)
	nOrdem := Iif(lGeraTitulo, nOrdem, oSecCab:GetOrder())   
EndIf

If ! FunName() $ "GPER060|GPEM650"
	Private cFilDe       := mv_par01
	Private cFilAte      := mv_par02
	Private cMatDe       := mv_par05
	Private cMatAte      := mv_par06
EndIf

nTpImpre := Iif(lGeraTitulo, 2, nTpImpre)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³  Altera o Titulo do Relatorio conforme o parametro selecionado   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
cTit  	 := OemToAnsi(STR0012) + DTOC(dDataDe) + " - " + DTOC(dDataAte)	//"RELATORIO DIRF MENSAL              Periodo: "
cTitulo  := If(AllTrim(lGper060 .Or. oReport:Title())==AllTrim(cTitulo),cTit,oReport:Title())

If Type('mv_par12') == 'N'
	lSalta   := Iif(mv_par12 == 1,.T.,.F.)
ElseIf Type('mv_par12') == 'C'
	lSalta   := Iif(mv_par12 == 'S',.T.,.F.)
EndIf

If nTpImpre == 1
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³  Altera o titulo do relatorio                                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oReport:SetTitle(cTit)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³  Quebra de pagina                                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If  nOrdem == 2  
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Quebrar por Centro de Custo                                      ³
		//³ Total Centro de Custo                                            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		oBreakCCusto:= TRBreak():New(IIf(cSinAna == 'A',oSecCab,oSection1), {||oSecCab:Cell(nRA_FILIAL):GetText()+'-'+oSecCab:Cell(nRA_CC):GetText()},OemToAnsi(STR0037), .F.)	//"Total do Centro de Custo"

		If lSalta
			oBreakCCusto:SetPageBreak()
		Endif
		TRFunction():New(oSection1:Cell(nNFL_LCR_BS ), , "SUM", oBreakCCusto, STR0062, "@E 999,999,999.99", ,.F., .F.) //Total Fol./Lucro Base
		TRFunction():New(oSection1:Cell(nNFL_LCR_IR ), , "SUM", oBreakCCusto, STR0063, "@E 999,999,999.99", ,.F., .F.) //Total Fol./Lucro IR
		TRFunction():New(oSection1:Cell(nNADIAN_BS  ), , "SUM", oBreakCCusto, STR0046, "@E 999,999,999.99", ,.F., .F.) //Total Adiant. Base
		TRFunction():New(oSection1:Cell(nNADIAN_IR  ), , "SUM", oBreakCCusto, STR0047, "@E 999,999,999.99", ,.F., .F.) //Total Adiant. IR
		TRFunction():New(oSection1:Cell(nNFER_BS    ), , "SUM", oBreakCCusto, STR0048, "@E 999,999,999.99", ,.F., .F.) //Total Ferias Base
		TRFunction():New(oSection1:Cell(nNFER_IR    ), , "SUM", oBreakCCusto, STR0049, "@E 999,999,999.99", ,.F., .F.) //Total Ferias IR
		TRFunction():New(oSection1:Cell(nN13SAL_BS  ), , "SUM", oBreakCCusto, STR0050, "@E 999,999,999.99", ,.F., .F.) //Total 13.Sal. Base
		TRFunction():New(oSection1:Cell(nN13SAL_IR  ), , "SUM", oBreakCCusto, STR0051, "@E 999,999,999.99", ,.F., .F.) //Total 13.Sal. IR
		TRFunction():New(oSection1:Cell(nNPLR_BS    ), , "SUM", oBreakCCusto, STR0058, "@E 999,999,999.99", ,.F., .F.) //Total PLR Base
		TRFunction():New(oSection1:Cell(nNPLR_IR    ), , "SUM", oBreakCCusto, STR0059, "@E 999,999,999.99", ,.F., .F.) //Total PLR IR
		TRFunction():New(oSection1:Cell(nNTOTAIS_BS ), , "SUM", oBreakCCusto, STR0052, "@E 999,999,999.99", ,.F., .F.) //Totais Bases
		TRFunction():New(oSection1:Cell(nNTOTAIS_IR ), , "SUM", oBreakCCusto, STR0053, "@E 999,999,999.99", ,.F., .F.) //Totais IR
	
		oBreakCCusto:OnBreak({|x,y| cTitCC:=OemToAnsi(STR0037)+": "+x})	//"Total do Centro de Custo"
		oBreakCCusto:SetTotalText({||cTitCC})
		
		oBreakCCusto:OnPrintTotal({|x,y| fPosQuebra()})
	EndIf
	
	oBreakFil:= TRBreak():New(IIf(cSinAna == 'A',oSecCab,oSection1), oSecCab:Cell("RA_FILIAL"),OemToAnsi(STR0036), .F.)	//"Total da Filial"
	oBreakFil:SetPageBreak()
	
	TRFunction():New(oSection1:Cell(nNFL_LCR_BS ), , "SUM", oBreakFil, STR0062, "@E 999,999,999.99", , .F., .T.) //Total Fol./Lucro Base
	TRFunction():New(oSection1:Cell(nNFL_LCR_IR ), , "SUM", oBreakFil, STR0063, "@E 999,999,999.99", , .F., .T.) //Total Fol./Lucro IR
	TRFunction():New(oSection1:Cell(nNADIAN_BS  ), , "SUM", oBreakFil, STR0046, "@E 999,999,999.99", , .F., .T.) //Total Adiant. Base
	TRFunction():New(oSection1:Cell(nNADIAN_IR  ), , "SUM", oBreakFil, STR0047, "@E 999,999,999.99", , .F., .T.) //Total Adiant. IR
	TRFunction():New(oSection1:Cell(nNFER_BS    ), , "SUM", oBreakFil, STR0048, "@E 999,999,999.99", , .F., .T.) //Total Ferias Base
	TRFunction():New(oSection1:Cell(nNFER_IR    ), , "SUM", oBreakFil, STR0049, "@E 999,999,999.99", , .F., .T.) //Total Ferias IR
	TRFunction():New(oSection1:Cell(nN13SAL_BS  ), , "SUM", oBreakFil, STR0050, "@E 999,999,999.99", , .F., .T.) //Total 13.Sal. Base
	TRFunction():New(oSection1:Cell(nN13SAL_IR  ), , "SUM", oBreakFil, STR0051, "@E 999,999,999.99", , .F., .T.) //Total 13.Sal. IR
	TRFunction():New(oSection1:Cell(nNPLR_BS    ), , "SUM", oBreakFil, STR0058, "@E 999,999,999.99", , .F., .T.) //Total PLR Base
	TRFunction():New(oSection1:Cell(nNPLR_IR    ), , "SUM", oBreakFil, STR0059, "@E 999,999,999.99", , .F., .T.) //Total PLR IR
	TRFunction():New(oSection1:Cell(nNTOTAIS_BS ), , "SUM", oBreakFil, STR0052, "@E 999,999,999.99", , .F., .T.) //Totais Bases
	TRFunction():New(oSection1:Cell(nNTOTAIS_IR ), , "SUM", oBreakFil, STR0053, "@E 999,999,999.99", , .F., .T.) //Totais IR
	
	oBreakFil:OnBreak({|x,y|cTitFil:=OemToAnsi(STR0036)+": "+x})	//"Total da Filial"
	oBreakFil:SetTotalText({||cTitFil})

	oSecCab:SetHeaderBreak  (.T.)
	oSecCab:SetHeaderPage   (.T.)

	oSection1:SetHeaderBreak  (.T.)
	oSection1:SetHeaderPage   (.T.)	

	ProcesDarf(lEnd)
	
	oSection1:Finish()
	oSecCab:Finish()
		
Else 

	If !lGeraTitulo
		oFont07	  := TFont():New("Arial"      , 10, 10, ,.F. ,,,,.T.,.F.)
		oFont08	  := TFont():New("Arial"      , 10, 10, ,.F. ,,,,.T.,.F.)  
		oFont10	  := TFont():New("Arial"      , 10, 10, ,.F. ,,,,.T.,.F.)
		oFont10n  := TFont():New("Arial"      , 10, 10, ,.T. ,,,,.T.,.F.)		//negrito
		oFont11	  := TFont():New("Courier New", 10, 10, ,.F. ,,,,.T.,.F.)
		oFont12   := TFont():New("Arial"	  , 12, 12, ,.F. ,,,,.T.,.F.)
		oFont15n  := TFont():New("Arial"      , 20, 20, ,.T. ,,,,.T.,.F.)		//negrito
		oFont21n  := TFont():New("Arial"      , 15, 15, ,.T. ,,,,.T.,.F.)		//negrito
		oPrint 	  := TMSPrinter():New(STR0041) 									//"DARF - Guia de Recolhimento DARF"
		
		FERASE("\spool\"+cNomeRel+".pdf")
		FERASE("\spool\"+cNomeRel+".rel")
		
		oPrint:= FWMSPrinter():New(cNomeRel+".rel",IMP_PDF,.T.,"\spool\",.T.,.F.,,,.T.,.T.)	
		oPrint:nDevice  := IMP_PDF
	    oPrint:cPathPDF := "\spool\"      
		oPrint:lServer  := .T.
		oPrint:lViewPDF := .F.	
		//oPrint:StartPage()
		/*wnrel     := SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,,,	.F., ,.T., 'M' )
		oPrint:StartPage()*/
		oPrint:SetPortrait()
	EndIf
	//Botão Cancelar
	If	nLastKey == 27
		Return
	EndIf
	
	cFilter := aReturn[7]

	If Type('mv_par12') == 'N'
		lSalta   := Iif(mv_par12 == 1,.T.,.F.)
	ElseIf Type('mv_par12') == 'C'
		lSalta   := Iif(mv_par12 == 'S',.T.,.F.)
	EndIf
	
		
	if !lGeraTitulo
		If nTpImpre # 1
			nTipImp := mv_par13+1
		EndIf
		dVencto   := mv_par14
		cNumRef   := mv_par15
		cCentra   := mv_par16
		lPLR      := If(mv_par17 == 1, .T., .F.)
	else // GPEM650
		Pergunte("GPM650", .F.)
		dVencto   := mv_par13
		cNumRef   := ""
		cCentra   := ""
	endif

	If FunName() == "GPER060"
		ProcesDarf()
	Else
		Processa( {|| ProcesDarf(@lEnd, cFilter)}, STR0054, STR0055, .F.)
	EndIf

	IF aReturn[5] == 3 .AND. nTipImp == 2
		oPrint:Print()
	Else
		if !lGeraTitulo // Não executa a impressão caso venha de GPEM650
			oPrint:Preview() // Visualiza impressao grafica antes de imprimir
		Endif
	ENDIF
EndIf
	
fVerTransf(.T.)

Return(Nil)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³fVerTransfºAutor  ³Mauricio MR         º Data ³  04/05/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Obtem as transferencias para tratamento de ferias			  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPER050			                                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function fVerTransf(lZera, aAuxTransf, cCompet, cCodEmp, cCodFil, cCodMat )
Static cChaveAnt:= '!!'

Default lZera	:= .F.

If lZera
   cChaveAnt := Nil
Else   
	If cChaveAnt <> ( cCodEmp + cCodFil + cCodMat )
		cChaveAnt  := ( cCodEmp + cCodFil + cCodMat )
		aAuxTransf := {}
		fTransf(@aAuxTransf, , Nil, Nil, Nil, Nil, .F., .T.,,,,, cCodFil, cCodMat)
	Endif	
Endif
Return(.T.)
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³fSoma     ºAutor  ³Mauricio MR         º Data ³  04/05/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Obtem as transferencias para tratamento de ferias			  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPER050			                                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function fSoma(cVetor,nVal,cCodVerba,dDataPagto,lSoma, cTipo2, cCCRat, cSemana, cRoteiro,cPer )

Local cChaveBusca := cCodVerba + DTOS(dDataPagto) + If( cTipo2 $ "G/R", "C", cTipo2) + cCCRat + cSemana + cRoteiro 
Local nFor 		  := 0
DEFAULT cPer 	  := ""

cChaveBusca += cPer

lSoma := If(lSoma == Nil,.F.,lSoma)

If ((aScan( aCodLido, cChaveBusca ) == 0 .Or. lRecalcIR) .AND. lSoma  ) .OR. ( !lSoma ) .OR. ( nVal < 0 )
	cVet := "a" + cVetor
	If ( lSoma )
		aAdd(aCodLido, cChaveBusca )
	EndIf	
	
	For nFor = 1 To 4
		&(cVet)[nFor] += nVal
	Next nFor
EndIf   

Return(Nil)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³FZeraAcumuºAutor  ³Mauricio MR         º Data ³  04/05/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Obtem as transferencias para tratamento de ferias			  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPER050			                                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function FZeraAcumuladores(nDe,nAte)
Local nFor := 0

For nFor := nDe To nAte
	aFolBas[nFor] := 0
	aAdiBas[nFor] := 0
	aFerBas[nFor] := 0
	a13Bas [nFor] := 0
	aFolIR [nFor] := 0
	aAdiIR [nFor] := 0
	aFerIR [nFor] := 0
	a13IR  [nFor] := 0
	aPLRBas[nFor] := 0
	aPLRIR [nFor] := 0
Next nFor
Return(Nil)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³FTotAcumulºAutor  ³Mauricio MR         º Data ³  04/05/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Obtem as transferencias para tratamento de ferias			  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPER050			                                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function FTotAcumuladores(nDe,nAte)
Local nTotal := 0
Local nFor	 := 0

For nFor := nDe To nAte
	nTotal += aFolBas[nFor]
	nTotal += aAdiBas[nFor]
	nTotal += aFerBas[nFor]
	nTotal += a13Bas [nFor]
	nTotal += aFolIR [nFor]
	nTotal += aAdiIR [nFor]
	nTotal += aFerIR [nFor]
	nTotal += a13IR  [nFor]
	nTotal += aPLRBas[nFor]
	nTotal += aPLRIR [nFor]
Next nFor 
Return(nTotal)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³fTestaTotaºAutor  ³Mauricio MR         º Data ³  04/05/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Executa Quebras                                             º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPER050			                                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function fTestaTotal()
cFilAnterior := (cAliasSRA)->RA_FILIAL
cFilQuebra   := (cAliasSRA)->RA_FILIAL
cCcAnt       := (cAliasSRA)->RA_CC

If !lGper060
	oSecCab:Cell(nRA_FILIAL):SetValue((cAliasSRA)->RA_FILIAL)
	oSecCab:Cell(nRA_CC    ):SetValue((cAliasSRA)->RA_CC)
	oSecCab:Cell(nRA_MAT   ):SetValue((cAliasSRA)->RA_MAT)
	oSecCab:Cell(nRA_NOME  ):SetValue((cAliasSRA)->RA_NOME)
EndIf
(cAliasSRA)->(dbSkip())

If Eof() 
	fImpCc()
	fImpFil()
	fImpEmp()
Elseif (cFilAnterior != (cAliasSRA)->RA_FILIAL  .And. Empty(cCentra) ) ;
		.Or. (cFilAnterior != (cAliasSRA)->RA_FILIAL .And. !Empty(cCentra) .And. nTipImp == 1); 
       .Or. (nTipImp # 1 .And. ((cAliasSRA)->RA_CODRET # cOldRet .And. !(cOldRet $ "3562/0561/    " .And. (cAliasSRA)->RA_CODRET $ "0561/    ")))
	fImpCc() 
	fImpFil()            
Elseif cCcAnt # (cAliasSRA)->RA_CC .And. !Eof()
	fImpCc() 
Endif
Return(Nil)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³fImpFun   ºAutor  ³Mauricio MR         º Data ³  04/05/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Imprime um Funcionario                                      º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPER050			                                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function fImpFun()

_nTipo := 4
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se Acumulador de funcionarios > 0                   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If FTotAcumuladores(4,4) == 0 
	Return(Nil)
Endif

If lImpRelato
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Imprime funcionario                                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	fImprime(4) 
ElseIf lGeraTitulo .And. lAgrupFunc  .And. FunName() == "GPEM650" .and. (cSinAna == "A" )
	fGravTit( (cAliasSRA)->RA_FILIAL, (cAliasSRA)->RA_CC, (cAliasSRA)->RA_MAT, aFolIR[4]+aAdiIR[4]+aFerIR[4]+a13IR[4] )
ElseIf FunName() == "GPER060"
	aFolBas2 := aClone(aFolBas) 
	aFolIR2  := aClone(aFolIR) 
	aFerBas2 := aClone(aFerBas) 
	aFerIR2  := aClone(aFerIR) 
	a13Bas2  := aClone(a13Bas) 
	a13IR2 	 := aClone(a13IR) 
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Zera Acumuladores do Funcionario                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
FZeraAcumuladores(4,4)  

Return(Nil)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³fImpCc    ºAutor  ³Mauricio MR         º Data ³  04/05/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Imprime Centro de Custo					                  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPER050			                                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function fImpCc()
_nTipo := 3

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se Acumulador de Centro de Custo > 0                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If FTotAcumuladores(3,3) == 0 
	Return(Nil)
Endif

If nOrdem ==  2
	If lImpRelato
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Imprime Tot Centro de Custo                                  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		fImprime(3) 
	ElseIf lGeraTitulo .And. lAgrupCc
		fGravTit( cFilAnterior, cCcAnt, , aFolIR[3]+aAdiIR[3]+aFerIR[3]+a13IR[3] )
	EndIf
Endif
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Zera Acumuladores de Centro de Custo                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
FZeraAcumuladores(3,3) 
Return(Nil)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³fImpFil   ºAutor  ³Mauricio MR         º Data ³  04/05/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Imprime Filial										      º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPER050			                                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function fImpFil()
Local lImpDarf	 := ExistBlock( "IMPDARF",.F.,.T. )//variavel p/ PE "IMPDARF" 

_nTipo:=2
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se Acumulador de Filial > 0                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If FTotAcumuladores(2,2) == 0 
	Return(Nil)
Endif

If !lGeraTitulo // GPEM650 não apresenta esta tela em seu processamento.
	If lImpDarf
		ExecBlock("IMPDARF",.F.,.F.)
	EndIf
EndIf

If lImpRelato
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Imprime total da filial                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	fImprime(2)  
ElseIf lGeraTitulo .And. lAgrupFil
	fGravTit( cFilAnterior, , , aFolIR[2]+aAdiIR[2]+aFerIR[2]+a13IR[2] )
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Zera Acumuladores de Filial                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
FZeraAcumuladores(2,2) 
Return(Nil)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³fImpEmp   ºAutor  ³Mauricio MR         º Data ³  04/05/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Imprime Total da Empresa									  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPER050			                                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function fImpEmp()
_nTipo := 1

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se Acumulador Geral > 0                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If FTotAcumuladores(1,1) == 0  
	Return(Nil)
Endif

If lImpRelato
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Imprime Acumulador Geral                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	fImprime(1) // 
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Zera Acumuladores Geral                                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
FZeraAcumuladores(1,1) 
Return(Nil)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³fImprime  ºAutor  ³Mauricio MR         º Data ³  04/05/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Imprime Totais Gerais nTipo: 								  º±±
±±º          ³ 4-Funcionario, 3-Centro de Custo, 2-Filial, 1- Empresa     º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPER050			                                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function fImprime(nTipo)
Local nTotLine := 0
_nTipo := nTipo

If nTipImp == 1 .And. nTpImpre == 1
	oSecCab:Cell(nRA_FILIAL):SetValue((cAliasSRA)->RA_FILIAL)
	oSecCab:Cell(nRA_CC    ):SetValue((cAliasSRA)->RA_CC)
	oSecCab:Cell(nRA_MAT   ):SetValue((cAliasSRA)->RA_MAT)
	oSecCab:Cell(nRA_NOME  ):SetValue((cAliasSRA)->RA_NOME)

	oSection1:Cell(nNFL_LCR_BS):SetValue(aFolBas[_nTipo])
	oSection1:Cell(nNFL_LCR_IR):SetValue(aFolIR [_nTipo])
	oSection1:Cell(nNADIAN_BS ):SetValue(aAdiBas[_nTipo])
	oSection1:Cell(nNADIAN_IR ):SetValue(aAdiIR [_nTipo])
	oSection1:Cell(nNFER_BS   ):SetValue(aFerBas[_nTipo])
	oSection1:Cell(nNFER_IR   ):SetValue(aFerIR [_nTipo])
	oSection1:Cell(nN13SAL_BS ):SetValue(a13Bas [_nTipo])
	oSection1:Cell(nN13SAL_IR ):SetValue(a13IR  [_nTipo])
	oSection1:Cell(nNPLR_BS   ):SetValue(aPLRBas[_nTipo])
	oSection1:Cell(nNPLR_IR   ):SetValue(aPLRIR [_nTipo])
	oSection1:Cell(nNTOTAIS_BS):SetValue(aFolBas[_nTipo] + aAdiBas[_nTipo] + aFerBas[_nTipo] + a13Bas[_nTipo] + aPLRBas[_nTipo])
	oSection1:Cell(nNTOTAIS_IR):SetValue(aFolIR [_nTipo] + aAdiIR [_nTipo] + aFerIR [_nTipo] + a13IR [_nTipo] + aPLRIR[_nTipo])
	If nTipo == 4
		If cSinAna == 'S'
			oSecCab:Hide()
			oSection1:Hide()
		EndIf
		nTotLine := oSecCab:report():row() //aterado para row() a pedido do Artur Fucher(Frame), nlinecount nao tava alimentando corretamente
		oSecCab:PrintLine()
		If cSinAna == 'S' .Or. ( oReport:nDevice == 4 ) .Or. oSecCab:report():row() <> nTotLine //Só imprime detalhe se tiver impresso cabeçalho
			oSection1:PrintLine()
		EndIf
	EndIf
EndIf
Return(Nil)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFunction  ³RetVerPro ºAutor  ³Microsiga           º Data ³  12/31/13   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Carrega verbas que serao usadas no processamento, asssim    º±±
±±º          ³evita processamento desnecessario                           º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function RetVerPro(aVerba, cFilSRV)
Local lRetorno := .F.

If FP_CODFOL(@aCodFol, cFilSRV)
	aAdd(aVerba, {aCodFol[0010][1]}) //Base IR Adiantamento
	aAdd(aVerba, {aCodFol[0009][1]}) //IR Adiantamento
	aAdd(aVerba, {aCodFol[0015][1]}) //Base IR Folha
	aAdd(aVerba, {aCodFol[0016][1]}) //Base IR Ferias
	aAdd(aVerba, {aCodFol[0027][1]}) //Base IR 13a Salário
	aAdd(aVerba, {aCodFol[0066][1]}) //IR Folha
	aAdd(aVerba, {aCodFol[0067][1]}) //IR Ferias
	aAdd(aVerba, {aCodFol[0071][1]}) //IR 13a Salário
	aAdd(aVerba, {aCodFol[0100][1]}) //Dif. Base IR Férias
	aAdd(aVerba, {aCodFol[0101][1]}) //Dif. IR Ferias
	aAdd(aVerba, {aCodFol[0659][1]}) //Vlr Compensação de IR
	aAdd(aVerba, {aCodFol[0974][1]}) //Base IR RRA
	aAdd(aVerba, {aCodFol[0978][1]}) //IR RRA
	aAdd(aVerba, {aCodFol[0979][1]}) //Base IR 13o Salario RRA
	aAdd(aVerba, {aCodFol[0983][1]}) //IR RRA 13o Salario
	aAdd(aVerba, {aCodFol[0835][1]}) //Base IR PLR
	aAdd(aVerba, {aCodFol[0152][1]}) //IR PLR
	aAdd(aVerba, {aCodFol[0106][1]}) //Base IR Mes Anterior
	aAdd(aVerba, {aCodFol[0107][1]}) //IR Mês Anterior
	lRetorno := .T.
	cVerbaSql := fTrataVer(aVerba)
Endif

Return(lRetorno)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFunction  ³ProcMenAcuºAutor  ³Microsiga           º Data ³  23/01/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Processa verbas nas tabelas SRC e SRD                       º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function ProcMovime(aPerAberto, aPerFechado, aVerba)
Local nVerba		:= 1
Local nTransf		:= 0
Local nLenaTransf	:= Len(aTransf)
Local lContinua		:= .T.
Local lRegCaixa		:= .F. 
Local aVerbasFunc	:= {}

cProcesso   := (cAliasSRA)->RA_PROCES

If nLenaTransf > 0
	For nTransf := 1 to nLenaTransf
		If aTransf[nTransf, 07] > dDataAte .and. !Empty(aTransf[nTransf, 14])
			cProcesso := aTransf[nTransf, 14]
		EndIf
		// Para geração de tít. de IR, verifica se existe pgto efetuado no mês
		// seguinte do calculo, caso tenha ocorrido transferencia de processo
		If !Empty(aTransf[nTransf, 14]) .and. lGeraTitulo .and. Left(cVerbas,3) == "003" .and. ChkDtPag(aTransf[nTransf, 14])
			cProcesso := aTransf[nTransf, 14]
		EndIf
	Next nTransf 
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Processa movimento SRC/SRD se exister periodo                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If aScan(aPerAberto , {|x| x[7] == cProcesso }) == 0 .And. ;
   aScan(aPerFechado, {|x| x[7] == cProcesso }) == 0
	Return()
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Carrega todas verbas do funcionario para processamento        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aVerbasFunc := RetornaVerbasFunc((cAliasSRA)->RA_FILIAL	,;	//-01 Filial
									(cAliasSRA)->RA_MAT		,;	//-02 Matricula
									''				,;	//-03 Centro de Custo
									''				,;	//-04 Roteiro
									cVerbaSql		,;	//-05 Verbas
									aPerAberto		,;	//-06 Periodo Aberto
									aPerFechado		,;	//-07 Periodo Fechado
									Nil			    ,;	//-08 Semana
									Nil				,;	//-09
									Nil				,;	//-09
									Nil				,;	//-09
									Nil				,;	//-09
									"C"				)	//-09

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Consiste controle de acessos								 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If (!Eval(cAcessaSRC)) .Or. (!Eval(cAcessaSRD))
	Return()
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ aVerbasFunc                                                   ³
//³ 01 Filial                                                     ³
//³ 02 Matricula                                                  ³
//³ 03 PD                                                         ³
//³ 04 Tipo 1                                                     ³
//³ 05 QtdSem                                                     ³
//³ 06 Horas                                                      ³
//³ 07 Valor                                                      ³
//³ 08 Semana                                                     ³
//³ 09 Parcela                                                    ³
//³ 10 Periodo                                                    ³
//³ 11 Roteiro                                                    ³
//³ 12 CC                                                         ³
//³ 13 DataPgt                                                    ³
//³ 14 DataArq                                                    ³
//³ 15 Sequencia                                                  ³
//³ 16 NumId                                                      ³
//³ 17 Tipo 2                                                     ³
//³ 18 Nulo                                                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
For nVerba := 1 To Len(aVerbasFunc)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica as transferencias para somar as verbas              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	lContinua 	:= .T.
	If nLenaTransf > 0
		For nTransf := nLenaTransf To 1 Step -1
			lRegCaixa := MesAno(aVerbasFunc[nVerba][13]) > aVerbasFunc[nVerba][10] // verifica se é regime caixa
			If aVerbasFunc[nVerba][13] <= aTransf[nTransf, 07] .Or. (aVerbasFunc[nVerba][13] >= aTransf[nTransf, 07] .and. MesAno(aVerbasFunc[nVerba][13]) > aVerbasFunc[nVerba][10] .and. !lRegCaixa)
				lContinua := (aTransf[nTransf, 08] + aTransf[nTransf, 09] )  == ( (cAliasSRA)->(RA_FILIAL+RA_MAT) )
			ElseIf aVerbasFunc[nVerba][13] >= aTransf[nTransf, 07]
				lContinua := (aTransf[nTransf, 10] + aTransf[nTransf, 11] )  == ( (cAliasSRA)->(RA_FILIAL+RA_MAT) )
				If aVerbasFunc[nVerba][3] == aCodFol[106,1] .or. aVerbasFunc[nVerba][3] == aCodFol[107,1]
					lContinua := .F.
				EndIf
			EndIf
			// ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ 
			// Quando o funcionário tem mais de uma transferencia dentro do mes,
			// a busca começa da ultima até primeira. Portanto, se já encontrar,
			// a ultima, deve sair do loop.
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If lContinua
				Exit
			Endif
		Next nTransf
	EndIf

	If ( dDataDe <= aVerbasFunc[nVerba][13] .And. dDataAte >= aVerbasFunc[nVerba][13] ) .And. lContinua
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Adiantamento de Salario                                      ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		SmMovAdi(aVerbasFunc[nVerba])
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Folha de Pagamento                                           ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		SmMovFol(aVerbasFunc[nVerba])
				
		If !lPLR
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Ferias                                                       ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			SmMovFer(aVerbasFunc[nVerba])	
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ 13§ Salario                                                  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			SmMov13S(aVerbasFunc[nVerba])						
	
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ RRA                                                          ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			SmMovRRA(aVerbasFunc[nVerba])
		EndIf
	EndIf
Next nVerba

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFunction  ³FolAdi    ºAutor  ³Microsiga           º Data ³  23/01/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Soma verba de adiantamento                                  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function SmMovAdi(aVerba)

If !lTitRRA .And. !lPLR 
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ IR do Adiantamento											 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If aVerba[03]  == aCodFol[0009][1] //IR do Adiantamento (Cod.Base para demonst.Folha)
		fSoma("ADIIR", aVerba[07], aVerba[03], aVerba[13],.T.,aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11])        
	EndIf
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Base IR do Adiantamento                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If aVerba[03] == aCodFol[0010][1] .And. aAdiIr[4] > 0//Base do I.R. no Adiantamento
		fSoma("ADIBAS", aVerba[07], aVerba[03], aVerba[13],.T.,aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11])                            
	EndIf
EndIf
Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFunction  ³FolAdi    ºAutor  ³Microsiga           º Data ³  23/01/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Soma verba de folha                                         º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function SmMovFol(aVerba)

If aVerba[17] $ "C*I*G*R" .And. !lPLR .And. !lTitRRA
 
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ IR Folha                                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If aVerba[03] == aCodFol[0066][1] //Desconto do Imposto de Renda                           
		fSoma("FOLIR" , aVerba[07]     , aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11],aVerba[10])
		lIRMesAnt := .F.
	EndIf
	 
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ IR Compensacao pago a maior                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If aVerba[03] == aCodFol[0659][1] //Vlr Compesacao de IR                                   
		fSoma("FOLIR" , aVerba[07]*(-1), aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11],aVerba[10])
	EndIf
	 
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Base IR Folha                                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If aVerba[03] == aCodFol[0015][1] .And. aFolIr[4] > 0  //Base Imposto de Renda                                  
		fSoma("FOLBAS", aVerba[07]     , aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11],aVerba[10])
	EndIf
EndIf

If aVerba[17] $ "C*I*G*F" .And. !lPLR .And. lIRMesAnt
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Base IR Mês Anterior                                         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If aVerba[03] == aCodFol[0106][1]
		fSoma("FOLBAS" , aVerba[07], aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11],aVerba[10])
	EndIf
	 
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ IR Mês Anterior                                              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If aVerba[03] == aCodFol[0107][1]
		fSoma("FOLIR" , aVerba[07], aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11],aVerba[10])
	EndIf
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Distribuicao de Lucros                                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
If aVerba[17] $ "C*I*G*A"  .And. ( lPLR .or. nTpImpre == 1 ) .And. !lTitRRA
 
 	If lPLR
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ IR Distribuicao de Lucros                                    ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
		If aVerba[03] == aCodFol[0152][1] //Imposto Renda da Verba Distribuicao de Lucro           
			fSoma("FOLIR" , aVerba[07], aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11],aVerba[10])
		EndIf
		 
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Base IR Distribuicao de Lucros                               ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	
		If aVerba[03] == aCodFol[0835][1] //Verba de Distribuicao de Lucro                         
			fSoma("FOLBAS", aVerba[07], aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11],aVerba[10])
		EndIf
	Else //Relatório DIRF
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ IR Distribuicao de Lucros                                    ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
		If aVerba[03] == aCodFol[0152][1] //Imposto Renda da Verba Distribuicao de Lucro           
			fSoma("PLRIR" , aVerba[07], aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11],aVerba[10])
		EndIf
		 
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Base IR Distribuicao de Lucros                               ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	
		If aVerba[03] == aCodFol[0835][1] //Verba de Distribuicao de Lucro                         
			fSoma("PLRBAS", aVerba[07], aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11],aVerba[10])
		EndIf	
	EndIf
EndIf

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFunction  ³FolAdi    ºAutor  ³Microsiga           º Data ³  23/01/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Soma verba de ferias                                        º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function SmMovFer(aVerba)	
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ IR Ferias ou Dif. IR Ferias                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
If ( aVerba[03] == aCodFol[067][1] .And. aVerba[17] $ "K*I*G*R" ) .Or. ; //Desconto do Imposto de Renda Ferias                    
   ( aVerba[03] == aCodFol[101][1] .And. aVerba[17] #  "R" )		//Diferenca de I.R. Ferias                               
	fSoma("FERIR" , aVerba[07], aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11])
EndIf
 
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Base IR Ferias ou Dif.Base IR Ferias                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
If (( aVerba[03] == aCodFol[016][1] .And. aVerba[17] $ "K*I*G*R" ) .Or.;	//Base Imposto de Renda Ferias                           
    ( aVerba[03] == aCodFol[100][1] .And. aVerba[17] #  "R" ))  	//Diferenca de Base I.R. Ferias                          
	fSoma("FERBAS", aVerba[07], aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11])
EndIf
 
Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFunction  ³FolAdi    ºAutor  ³Microsiga           º Data ³  23/01/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Soma verba de 13o salario                                   º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function SmMov13S(aVerba)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ IR 13 Salario                                                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
If aVerba[03] == aCodFol[0071][1] //Imposto de Renda sobre 13o.Salario                     
	fSoma("13IR" ,aVerba[07], aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11])
EndIf
 
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Base IR 13 Salario                                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
If aVerba[03] == aCodFol[0027][1] .And. a13Ir[4] > 0 //Base I.R. no 13o.Salario                               
	fSoma("13BAS", aVerba[07], aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11])
EndIf

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFunction  ³SmMovRRA  ºAutor  ³Microsiga           º Data ³  23/01/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Soma verba de RRA                                           º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function SmMovRRA(aVerba)

 If !lTitRRA
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ RRA - IR                                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
	If aVerba[03] == aCodFol[0978][1] //IR RRA                                                                      
		fSoma("FOLIR" ,aVerba[07], aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11])
	EndIf
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ RRA - BASE IR                                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
	If aVerba[03] == aCodFol[0974][1] //Base IR RRA                                                           
		fSoma("FOLBAS" ,aVerba[07], aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11])
	EndIf
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ RRA - IR 13 Salario                                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
	If aVerba[03] == aCodFol[0979][1] //Base IR 13o.RRA                                        
		fSoma("13IR" ,aVerba[07], aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11])
	EndIf
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ RRA - IR 13 Salario                                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
	If aVerba[03] == aCodFol[0983][1] //IR RRA 13o                                             
		fSoma("13IR" ,aVerba[07], aVerba[03], aVerba[13], .T., aVerba[17], aVerba[12]+aVerba[21]+aVerba[22], aVerba[08], aVerba[11])
	EndIf
EndIf	
Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFunction  ³FolAdi    ºAutor  ³Microsiga           º Data ³  23/01/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Procura no SRG Funcionarios Demitidos                      º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function ProcRescisao() 
Local nX 			:= 1
Local aRecnoSRG	:= {}
Local aRecnoSRGD 	:= {}
Local nPosAbert	:= 0
//Local nPosFech	:= 0
Local aAuxPer 	:= {}
Local cRotRes	:= fGetCalcRot("4")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Consiste controle de acessos								 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !Eval(cAcessaSRG)
	Return()
EndIf

While !Eof() .And. (cAliasSRA)->(RA_FILIAL+RA_MAT) == SRG->(RG_FILIAL+RG_MAT)
	If SRG->RG_EFETIVA = "S" .And. (SRG->RG_DATAHOM >= dDataDe .And. SRG->RG_DATAHOM <= dDataAte )

		// Se periodo foi integrado, não verifica os registros de Rescisao
		// pois estes ja foram integrados a Folha
		fRetPerComp( SubStr( SRG->RG_PERIODO, 5 ), SubStr( SRG->RG_PERIODO, 1, 4) , xFilial('RCH', (cAliasSRA)->RA_FILIAL), SRG->RG_PROCES, cRotRes, NIL , NIL , @aAuxPer)
		nPosAbert := aScan(aAuxPer,{|x| x[1] + x[2] + x[8] + x[7]  == SRG->(RG_PERIODO + RG_SEMANA + RG_ROTEIR + RG_PROCES) }) 
		If nPosAbert > 0 .AND. !Empty(aAuxPer[nPosAbert][11])
			SRG->(dbSkip())
		 	Loop
		Endif
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Monta array com dados da rescisao                			 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aAdd(aRecnoSRG,{SRG->(RG_FILIAL+RG_MAT), SRR->RR_DATAPAG, SRG->RG_DATAHOM, SRG->RG_DATADEM, SRG->(RECNO())})
		
		dbSelectArea( "SRR" )
		dbSetOrder(1)
		If dbSeek( (cAliasSRA)->(RA_FILIAL+RA_MAT) + "R" + DtoS(SRG->RG_DTGERAR))
			While SRR->(!Eof()) .And. (cAliasSRA)->(RA_FILIAL+RA_MAT) + "R" + DtoC(SRG->RG_DTGERAR) == ;
							          SRR->(RR_FILIAL+RR_MAT) + "R" + DtoC(SRR->RR_DATA)
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Folha de Pagamento                                           ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
 				If !lPLR
					If !lTitRRA

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ IR Folha                                                     ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
						If SRR->RR_PD == aCodFol[0066][1]
							fSoma("FOLIR", SRR->RR_VALOR, SRR->RR_PD, SRR->RR_DATAPAG, .T., SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
						EndIf
		
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Base IR Folha                                                ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If SRR->RR_PD == aCodFol[0015][1] .And. aFolIr[4] > 0
							fSoma("FOLBAS", SRR->RR_VALOR, SRR->RR_PD, SRR->RR_DATAPAG, .T., SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
						EndIf                                                             
					Else

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ RRA - IR                                                     ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
						If SRR->RR_PD == aCodFol[0978][1] //IR RRA                                                                      
							fSoma("FOLIR" , SRR->RR_VALOR, SRR->RR_PD, SRR->RR_DATAPAG, .T., SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
						EndIf
						
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ RRA - BASE IR                                                ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
						If SRR->RR_PD == aCodFol[0974][1] //Base IR RRA                                                           
							fSoma("FOLBAS" , SRR->RR_VALOR, SRR->RR_PD, SRR->RR_DATAPAG, .T., SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
						EndIf
						
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ RRA - IR 13 Salario                                          ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
						If SRR->RR_PD == aCodFol[0979][1] //Base IR 13o.RRA                                        
							fSoma("13IR"  , SRR->RR_VALOR, SRR->RR_PD, SRR->RR_DATAPAG, .T., SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
						EndIf
						
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ RRA - IR 13 Salario                                          ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
						If SRR->RR_PD == aCodFol[0983][1] //IR RRA 13o                                             
							fSoma("13IR"  , SRR->RR_VALOR, SRR->RR_PD, SRR->RR_DATAPAG, .T., SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
						EndIf
					EndIf
				EndIf

				If !lTitRRA
					If lPLR
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Distribuicao de Lucros                                       ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						// IR Distribuicao de Lucros
						If SRR->RR_PD == aCodFol[152][1] .and. SRR->RR_TIPO2 # "A"
							fSoma("FOLIR",SRR->RR_VALOR,SRR->RR_PD,SRR->RR_DATAPAG,.T.,SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
						Endif
						// Base IR Distribuicao de Lucros
						If SRR->RR_PD == aCodFol[151][1] .And. aFolIr[4] > 0 .and. SRR->RR_TIPO2 # "A"
							fSoma("FOLBAS",SRR->RR_VALOR,SRR->RR_PD,SRR->RR_DATAPAG,.T.,SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
						Endif
					Else
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Ferias                                                       ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		 
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ IR Ferias ou Dif.IR Ferias                                   ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If (SRR->RR_PD == aCodFol[0067][1] .Or. SRR->RR_PD == aCodFol[101,1]) .and. SRR->RR_DATAPAG == SRG->RG_DATAHOM
							fSoma("FERIR", SRR->RR_VALOR, SRR->RR_PD, SRR->RR_DATAPAG, .T., SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
						EndIf
		 
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Base IR Ferias ou Dif.Base IR Ferias                         ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If (SRR->RR_PD == aCodFol[0016][1] .Or. SRR->RR_PD == aCodFol[100,1] ) .And. aFerIr[4] > 0 .and. SRR->RR_DATAPAG == SRG->RG_DATAHOM
							fSoma("FERBAS", SRR->RR_VALOR, SRR->RR_PD, SRR->RR_DATAPAG, .T., SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
						EndIf
						
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ 13§ Salario                                                  ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ IR 13 Salario                                                ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If SRR->RR_PD == aCodFol[0071][1]
							fSoma("13IR", SRR->RR_VALOR, SRR->RR_PD, SRR->RR_DATAPAG, .T., SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
						EndIf
		
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Base IR 13 Salario                                           ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If SRR->RR_PD == aCodFol[0027][1] .And.a13Ir[4] > 0
							fSoma("13BAS", SRR->RR_VALOR, SRR->RR_PD, SRR->RR_DATAPAG, .T., SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
						EndIf
					EndIf
				EndIf			
				SRR->(dbSkip())
			EndDo
		EndIf
	EndIf
	dbSelectArea("SRG")
	SRG->(dbSkip())
EndDo

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Define as rescisoes que devem ter o Ir abatido.                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
For nX := 1 to Len(aRecnoSRG)
	dbSelectArea("SRG")
	dbGoTo(aRecnoSRG[nX][5])
	SRG->(dbSkip(-1))
	If	SRG->(RG_FILIAL+RG_MAT) == aRecnoSRG[nx][1] .And. ;
		MesAno(SRG->RG_DTGERAR) == MesAno(aRecnoSRG[nX][2]) .And. ;
		MesAno(SRG->RG_DTGERAR) == MesAno(SRG->RG_DATADEM)  .And. ;
		!SRG->(BoF())
		aAdd(aRecnoSRGD, {SRG->(RG_FILIAL+RG_MAT), SRG->RG_DTGERAR, SRG->RG_DATAHOM, SRG->RG_DATADEM, SRG->(Recno())})
	EndIf
Next nX

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ajusta os valores de ir de rescisoes complementares dentro do mes³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea( "SRR" )
lRecalcIR := .F.
For nX := 1 to Len(aRecnoSRGD)
	If !lPLR
		If !lTitRRA

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Folha de Pagamento                                           ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		 
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ IR Folha                                                     ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If SRR->(dbSeek( aRecnoSRGD[nx,1] + "R" + DtoS(aRecnoSRGD[nx,2]) + aCodFol[66][1] )) 
				lRecalcIR := .T.
				fSoma("FOLIR",SRR->RR_VALOR*(-1),SRR->RR_PD,SRR->RR_DATAPAG,.T.,SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			Endif
		 
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Base IR Folha                                                ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If SRR->(dbSeek( aRecnoSRGD[nx,1] + "R" + DtoS(aRecnoSRGD[nx,2]) + aCodFol[15][1] )) 
				fSoma("FOLBAS",SRR->RR_VALOR*(-1),SRR->RR_PD,SRR->RR_DATAPAG,.T.,SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			Endif
		Else
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ RRA - IR                                                     ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
			If SRR->(dbSeek( aRecnoSRGD[nx,1] + "R" + DtoS(aRecnoSRGD[nx,2]) + aCodFol[0978][1] )) //IR RRA                                                                      
				fSoma("FOLIR" , SRR->RR_VALOR, SRR->RR_PD, SRR->RR_DATAPAG, .T., SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			EndIf
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ RRA - BASE IR                                                ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
			If SRR->(dbSeek( aRecnoSRGD[nx,1] + "R" + DtoS(aRecnoSRGD[nx,2]) + aCodFol[0974][1] )) //Base IR RRA                                                           
				fSoma("FOLBAS" , SRR->RR_VALOR, SRR->RR_PD, SRR->RR_DATAPAG, .T., SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			EndIf
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ RRA - IR 13 Salario                                          ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
			If SRR->(dbSeek( aRecnoSRGD[nx,1] + "R" + DtoS(aRecnoSRGD[nx,2]) + aCodFol[0979][1] )) //Base IR 13o.RRA                                        
				fSoma("13IR"  , SRR->RR_VALOR, SRR->RR_PD, SRR->RR_DATAPAG, .T., SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			EndIf
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ RRA - IR 13 Salario                                          ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ				
			If SRR->(dbSeek( aRecnoSRGD[nx,1] + "R" + DtoS(aRecnoSRGD[nx,2]) + aCodFol[0983][1] )) //IR RRA 13o                                             
				fSoma("13IR"  , SRR->RR_VALOR, SRR->RR_PD, SRR->RR_DATAPAG, .T., SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			EndIf		
		EndIf
	EndIf
	
	If !lTitRRA
		If lPLR
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Distribuicao de Lucros                                       ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			// IR Distribuicao de Lucros
			If dbSeek( aRecnoSRGD[nx,1] + "R" + DtoS(aRecnoSRGD[nx,2]) + aCodFol[152][1] ) .And. aFolIr[4] > 0
				fSoma("FOLIR",SRR->RR_VALOR*(-1),SRR->RR_PD,SRR->RR_DATAPAG,.T.,SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			Endif
			// Base IR Distribuicao de Lucros
			If dbSeek( aRecnoSRGD[nx,1] + "R" + DtoS(aRecnoSRGD[nx,2]) + aCodFol[151][1] ) .And. aFolBas[4] > 0
				fSoma("FOLBAS",SRR->RR_VALOR*(-1),SRR->RR_PD,SRR->RR_DATAPAG,.T.,SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			Endif
		Else

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Ferias                                                       ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		 
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ IR Ferias                                                    ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If SRR->(dbSeek( aRecnoSRGD[nx,1] + "R" + DtoS(aRecnoSRGD[nx,2]) + aCodFol[67][1] )) 
				fSoma("FERIR",SRR->RR_VALOR*(-1),SRR->RR_PD,SRR->RR_DATAPAG,.T.,SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			Endif
		 
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Dif.IR Ferias                                                ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If SRR->(dbSeek( aRecnoSRGD[nx,1] + "R" + DtoS(aRecnoSRGD[nx,2]) + aCodFol[101][1] ))
				fSoma("FERIR",SRR->RR_VALOR*(-1),SRR->RR_PD,SRR->RR_DATAPAG,.T.,SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			Endif
		 
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Base IR Ferias                                               ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If SRR->(dbSeek( aRecnoSRGD[nx,1] + "R" + DtoS(aRecnoSRGD[nx,2]) + aCodFol[16][1] )) 
				fSoma("FERBAS",SRR->RR_VALOR*(-1),SRR->RR_PD,SRR->RR_DATAPAG,.T.,SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			Endif
		 
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Dif.Base IR Ferias                                           ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If SRR->(dbSeek( aRecnoSRGD[nx,1] + "R" + DtoS(aRecnoSRGD[nx,2]) + aCodFol[100][1] ))
				fSoma("FERBAS",SRR->RR_VALOR*(-1),SRR->RR_PD,SRR->RR_DATAPAG,.T.,SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			Endif
		
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ 13§ Salario                                                  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ IR 13 Salario                                                ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If SRR->(dbSeek( aRecnoSRGD[nx,1] + "R" + DtoS(aRecnoSRGD[nx,2]) + aCodFol[71][1] )) 
				fSoma("13IR",SRR->RR_VALOR*(-1),SRR->RR_PD,SRR->RR_DATAPAG,.T.,SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			Endif 
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Base IR 13 Salario                                           ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ		
			If SRR->(dbSeek( aRecnoSRGD[nx,1] + "R" + DtoS(aRecnoSRGD[nx,2]) + aCodFol[27][1] )) 
				fSoma("13BAS",SRR->RR_VALOR*(-1),SRR->RR_PD,SRR->RR_DATAPAG,.T.,SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			Endif
		EndIf
	EndIf
Next nX

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFunction  ³FolAdi    ºAutor  ³Microsiga           º Data ³  23/01/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Procura no SRH Funcionarios em Ferias                      º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function ProcFerias()
Local dDtBusFer 	:= CtoD("")
Local lSegRecibo	:= .F.


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Tratamento de transferencias                                     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local cDataRecib	:= ""
Local lExitLoop		:= .F.
Local nTransf		:= 0
Local nLenaTransf	:= 0	
Local aAuxPer		:= {}
Local cRotFer		:= fGetCalcRot("3") 
Local nPosAbert		:= 0
	
dbSelectArea( "SRH" )
If SRH->(!dbSeek( (cAliasSRA)->(RA_FILIAL+RA_MAT )))
	Return()
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Consiste controle de acessos								 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !Eval(cAcessaSRH)
	Return()
EndIf

If lTitRRA
	Return()
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Carrega as Transferencias para o AnoMes do DARF              ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ		
While SRH->(!Eof()) .And. (cAliasSRA)->(RA_FILIAL+RA_MAT) == SRH->(RH_FILIAL+RH_MAT)
	
	fRetPerComp( SubStr( SRH->RH_PERIODO, 5 ), SubStr( SRH->RH_PERIODO, 1, 4) , xFilial('RCH', (cAliasSRA)->RA_FILIAL), SRH->RH_PROCES, cRotFer, NIL , NIL , @aAuxPer)
	nPosAbert := aScan(aAuxPer,{|x| x[1] + x[2] + x[8] + x[7]  == SRH->(RH_PERIODO + RH_NPAGTO + RH_ROTEIR + RH_PROCES) }) 
	If nPosAbert > 0 .AND. !Empty(aAuxPer[nPosAbert][11])
		SRH->(dbSkip())
	 	Loop
	Endif

	
	dDtBusFer := fDtBusFer() 
	If Type('dDtBusFer') # 'D'
		dDtBusFer := SRH->RH_DATAINI
	EndIf
	If (SRH->RH_DTRECIB >= dDataDe .And. SRH->RH_DTRECIB <= dDataAte )
	  					              
		nLenaTransf	:= Len(aTransf)
		cDataRecib	:= Dtos(SRH->RH_DTRECIB)
		lExitLoop	:= .F.
		For nTransf := nLenaTransf To 1 Step -1 
        	If cDataRecib >= Dtos(aTransf[nTransf, 07])
            	If !( (aTransf[nTransf, 10] + aTransf[nTransf, 11] )  == ( (cAliasSRA)->(RA_FILIAL+RA_MAT) ) )
                	lExitLoop	:= .T.
				Endif     
				Exit
			ElseIf nTransf == 1
				If !( (aTransf[nTransf, 08] + aTransf[nTransf, 09] )  == ( (cAliasSRA)->(RA_FILIAL+RA_MAT) ) )
					lExitLoop	:= .T.
				Endif     
				Exit
			EndIf
		Next nTransf  
                
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica se desconsidera os movimentos de ferias devido aos  ³
		//³ dados serem resultado de uma tranferencia                    |
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
        If lExitLoop 
        	SRH->(dbSkip())
            Loop
		Endif   
		
		dbSelectArea( "SRR" )
		dbSetOrder(1)
		If SRR->(dbSeek( (cAliasSRA)->(RA_FILIAL+RA_MAT) + "F" + DtoS(dDtBusFer) + aCodfol[067,1] ))
			fSoma("FERIR", SRR->RR_VALOR, SRR->RR_PD, SRH->RH_DTRECIB, lSegRecibo, SRR->RR_TIPO2, SRR->RR_CC, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			If SRR->(dbSeek( (cAliasSRA)->(RA_FILIAL+RA_MAT) + "F" + DtoS(dDtBusFer) + aCodfol[101,1] ))
				fSoma("FERIR", SRR->RR_VALOR, SRR->RR_PD, SRH->RH_DTRECIB, lSegRecibo, SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
			EndIf
			If SRR->(dbSeek( (cAliasSRA)->(RA_FILIAL+RA_MAT) + "F" + DtoS(dDtBusFer) + aCodfol[016,1] )) .And.;
			   aFerIr[4] > 0 
				fSoma("FERBAS", SRR->RR_VALOR, SRR->RR_PD, SRH->RH_DTRECIB, lSegRecibo, SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
				If SRR->(dbSeek( (cAliasSRA)->(RA_FILIAL+RA_MAT) + "F" + DtoS(dDtBusFer) + aCodfol[100,1] ))
					fSoma("FERBAS", SRR->RR_VALOR, SRR->RR_PD, SRH->RH_DTRECIB, lSegRecibo, SRR->RR_TIPO2, SRR->RR_CC+SRR->RR_ITEM+SRR->RR_CLVL, SRR->RR_SEMANA, SRR->RR_ROTEIR )
				Endif
			Endif
			lSegRecibo := .T.
		Endif
	Endif
	dbSelectArea("SRH")
	SRH->(dbSkip())
EndDo

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³fRadioPerg³ Autor ³ Tania Bronzeri        ³ Data ³04/09/2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Monta dialogo para selecao com botoes de radio             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function fRadioPerg(nOpcRadio)
Local nOpcAux		:= 0
Local oRadio		:= Nil
Local oDlg			:= Nil
Local oGroup		:= Nil
Local oFont			:= Nil
//Local nReg			:= Nil
Local aAdvSize		:= {}
Local aInfoAdvSize	:= {}
Local aObjSize		:= {}
Local aObjCoords	:= {}
Local aButtons		:= {}
Local bSet15		:= { || NIL }
Local bSet24		:= { || NIL }

nOpcAux   := nOpcRadio
nOpcRadio := 0

DEFINE FONT oFont NAME "Arial" SIZE 0,-11 BOLD

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Monta as Dimensoes dos Objetos         					     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aAdvSize		:= MsAdvSize()
aAdvSize[5]		:= (aAdvSize[5]/100) * 60	//horizontal
aAdvSize[6]		:= (aAdvSize[6]/100) * 50	//Vertical
aInfoAdvSize	:= { aAdvSize[1] , aAdvSize[2] , aAdvSize[3] , aAdvSize[4] , 0 , 0 }					 
aAdd( aObjCoords , { 000 , 000 , .T. , .T. } )
aObjSize		:= MsObjSize( aInfoAdvSize , aObjCoords )
aGdCoord		:= { (aObjSize[1,1]+3), (aObjSize[1,2]+5), (((aObjSize[1,3])/100)*60), (((aObjSize[1,4])/100)*50) }	//1,3 Vertical /1,4 Horizontal

DEFINE MSDIALOG oDlg TITLE OemToAnsi( STR0001 ) From aAdvSize[7],0 TO aAdvSize[6],aAdvSize[5] OF oMainWnd PIXEL

	@ aGdCoord[1]+5 , aGdCoord[2] GROUP oGroup TO (aGdCoord[3]/1.5),aGdCoord[4]+10 LABEL OemToAnsi(STR0040) OF oDlg PIXEL	//"Dirf Mensal / Darf"
	oGroup:oFont:=oFont
	         
	@ aGdCoord[1]+17 , aGdCoord[2]+25 RADIO oRadio VAR nOpcAux	ITEMS OemToAnsi(STR0038),OemToAnsi(STR0039)		;	//
										SIZE 150,010 OF oDlg PIXEL	//"Relatorio Dirf Mensal"###"Darf"
	
	bSet15		:= { || nOpcRadio := nOpcAux, oDlg:End() }
	bSet24		:= { || nOpcRadio := -1,      oDlg:End() }

ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar( oDlg , bSet15 , bSet24 , NIL , aButtons )

Return( nOpcRadio )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ProcesDARFºAutor  ³RH                  º Data ³  04/05/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Obtem as transferencias para tratamento de ferias			  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPER050			                                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function ProcesDarf(lEnd, cFiltro) 

Local cWhereSRA  := ""
Local cOrderSRA  := ""
Local cCamposSRA := ""
Local cValidFil	 := ""
Local nX		 := 0
Local aValidFil	 := StrToArray(fValidFil(),"/") //array com as filiais que o usuario possui acesso
Local cUserFilt	 := ""

Private aTransf	 := {}
Private cAcessaSRC 	:= &("{ || " + ChkRH("GPER050","SRC","2") + "}")
Private cAcessaSRD 	:= &("{ || " + ChkRH("GPER050","SRD","2") + "}")
Private cAcessaSRG 	:= &("{ || " + ChkRH("GPER050","SRG","2") + "}")
Private cAcessaSRH 	:= &("{ || " + ChkRH("GPER050","SRH","2") + "}")
Private lImpPre := .T.
SetPrvt("NVEZ,NLIDARF")

Default cFiltro := ""

Static cAliasSRA := ""
cAliasSRA := "QRYSRA"

If !lGeraTitulo
	cPerg := 'GPR050'
	If nTpImpre == 1
		cPerg := 'GP050R'
	EndIf
	Pergunte(cPerg, .F.)
	cFilDe       := mv_par01
	cFilAte      := mv_par02
	cCcDe        := mv_par03
	cCcAte       := mv_par04
	cMatDe       := mv_par05
	cMatAte      := mv_par06
	cNomDe       := mv_par07
	cNomAte      := mv_par08
	dDataDe      := mv_par09
	dDataAte     := mv_par10
	cSinAna      := Iif(mv_par11 == 1,"A","S")
ElseIf FunName() == "GPER060"
	Pergunte("GPR060", .F.)
	cCcDe        := mv_par03
	cCcAte       := mv_par04
	cNomDe       := Space(30)
	cNomAte      := Replicate("Z", 30)
	cDataRef	 := dToS(mv_par05)
	dDataDe 	 := cToD( "01/" + SubStr( cDataRef, 5, 2 ) + "/" + SubStr( cDataRef, 1, 4 ) )
	dDataAte     := cToD( StrZero( f_UltDia( dDataDe ), 2) + "/" + SubStr( cDataRef, 5, 2 ) + "/" + SubStr( cDataRef, 1, 4 ) )
	cSinAna      := "A"//Iif(mv_par11 == 1,"A","S")
Else//GPEM650
	Pergunte("GPM650", .F.)
	cCcDe        := mv_par03
	cCcAte       := mv_par04
	cMatDe       := mv_par05
	cMatAte      := mv_par06
	cNomDe       := Space(30)
	cNomAte      := Replicate("Z", 30)
	dDataDe      := mv_par07
	dDataAte     := mv_par08
	cSinAna      := "A"//Iif(mv_par11 == 1,"A","S")
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Define os periodos onde devem ser lidos os identificadores de³
//³ verbas de folha de pagamento e adiantamento de salario.      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If MesAno(dDataDe) <> MesAno(dDataAte) 
	If lImpRelato  
		Aviso(OemToAnsi(STR0020),OemToAnsi(STR0021), { "OK"} )	//"Aviso"###"As datas inicial e final devem estar dentro do mesmo mês e ano. Verifique."
	EndIf
	Return(Nil)
EndIf

If !Empty(cCentra) .And. nTpImpre != 1
	if ! (fInfo(@aInfo,cCentra))
		Aviso(OemToAnsi(STR0020),OemToAnsi(STR0064), { "OK"} )
		Return(Nil)
	endif	
Endif 



//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Cria indice para Relatorio de IR.                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If nTpImpre == 1
	If nOrdem == 1
		cOrderSRA := "%RA_FILIAL, RA_MAT%"
	ElseIf nOrdem == 2
		cOrderSRA := "%RA_FILIAL, RA_CC, RA_MAT%" 
	ElseIf nOrdem == 3
		cOrderSRA := "%RA_FILIAL, RA_NOME ,RA_MAT%" 
	Endif
Else
	If nOrdem == 1
		cOrderSRA := Iif( Empty( cCentra ), "%RA_FILIAL, RA_CODRET, RA_MAT%", "%RA_CODRET, RA_FILIAL, RA_MAT%")
	ElseIf nOrdem == 2
		cOrderSRA := Iif( Empty( cCentra ), "%RA_FILIAL, RA_CODRET, RA_CC, RA_MAT%", "%RA_CODRET, RA_FILIAL, RA_CC, RA_MAT%") 
	ElseIf nOrdem == 3
		cOrderSRA := Iif( Empty( cCentra ), "%RA_FILIAL, RA_CODRET, RA_NOME, RA_MAT%", "%RA_CODRET, RA_FILIAL, RA_NOME ,RA_MAT%") 
	Endif
Endif

aFill(aFolBas, 0)
aFill(aAdiBas, 0)
aFill(aFerBas, 0)
aFill(a13Bas , 0)
aFill(aPLRBas, 0)
aFill(aFolIR , 0)
aFill(aAdiIR , 0)
aFill(aFerIR , 0)
aFill(a13IR  , 0)
aFill(aPLRIR , 0)

cFilAnterior 	:= Replicate("!", FWGETTAMFILIAL)
cFilQuebra      := Replicate("!", FWGETTAMFILIAL)
cCcAnt  		:= "!!!!!!!!!"

If nTipImp == 1 .And. nTpImpre == 1
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Incializa impressao                                              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	oSecCab:Init()
	oSection1:Init()
	cUserFilt := oSecCab:GetUserExp( "SRA",.T.)
 
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Define o total da regua da tela de processamento do relatorio    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oReport:SetMeter( SRA->(RecCount()) )
Else
	If FunName() != "GPER060"
		ProcRegua(SRA->(RecCount()))
	EndIf
EndIf

	cCamposSRA := "%RA_FILIAL, RA_MAT, RA_NOME, RA_CC, RA_PROCES, RA_CODRET%"

	cWhereSRA := "%SRA.RA_FILIAL >= " + "'" + cFilDe  + "'" + " AND "
	cWhereSRA += "SRA.RA_FILIAL <= " + "'" + cFilAte + "'" + " AND "
	cWhereSRA += "SRA.RA_MAT >= " + "'" + cMatDe + "'" + " AND "
	cWhereSRA += "SRA.RA_MAT <= " + "'" + cMatAte + "' " 
	If FunName() == "GPER060"
		cWhereSRA += "AND SRA.RA_TPCONTR IN (" + fSqlIN(cTpC1, 1) + ")" 
	EndIf	
	If !empty(cUserFilt)
		cWhereSRA += " AND " + cUserFilt
	EndIf	
	cWhereSRA +=  "%"

	//Filtra filiais de acesso do usuario
	cValidFil := "%RA_FILIAL IN ('' "
	For nX := 1 to Len(aValidFil)
		cValidFil += ", '" + aValidFil[nX] + "' "
	Next nX
	cValidFil += ") %"

	If Select(cAliasSRA) > 0
		(cAliasSRA)->( dbCloseArea() )
	EndIf

	BeginSql alias cAliasSRA
		SELECT %exp:cCamposSRA%
		FROM  %table:SRA% SRA
		WHERE %exp:cWhereSRA% AND %exp:cValidFil% AND SRA.%notDel%	
		ORDER BY %exp:cOrderSRA%
	EndSql

IF nTipImp == 2
	oPrint:StartPage()  //Inicio da Página
ENDIF
While (cAliasSRA)->(!EoF())

	//Posiciona na SRA para que os filtros personalizados sejam executados.
	SRA->(DbSetOrder(1))
	SRA->(DbSeek((cAliasSRA)->(RA_FILIAL + RA_MAT)))

	cOldRet := (cAliasSRA)->RA_CODRET
	cSRACodRet := If(Empty(cOldRet), "0561", cOldRet)

	If !Empty(cFiltro) .And. !SRA->(&(cFiltro))
		fTestaTotal()
		Loop
	EndIf	

	If !lGeraTitulo .and. nTpImpre # 1
		If lPlr
			cOldRet := "3562"
		EndIf
	EndIf 

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Movimenta Cursor                                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If nTipImp == 1 .And. nTpImpre == 1
		oReport:IncMeter(1)
	Else
		If FunName() != "GPER060"
			If lGeraTitulo
				IncProc(STR0019) //"Gerando Titulos - Imposto de Renda"
			Else
				IncProc(STR0055) //"Aguarde..."
			EndIf
		EndIf
	EndIf

	If lEnd
		Exit
	EndIf
	
	If (cAliasSRA)->RA_FILIAL # cFilQuebra .or. Empty(aCodFol)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Carregar os periodos abertos (aPerAberto) e/ou os periodos   ³
		//³ fechados (aPerFechado), de acordo com uma determinada compe- ³
		//³ tencia.                 									 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aPerAberto 	:= {}
		aPerFechado := {}
		fRetPerComp( Month2Str( dDataDe ), Year2Str(dDataDe ), xFilial('RCH', (cAliasSRA)->RA_FILIAL), Nil, Nil, @aPerAberto, @aPerFechado,Nil,.T.,dDataDe,dDataAte)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Carrega verbas que serao processadas                         ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ		
		If !RetVerPro(@aVerba, xFilial('SRV', (cAliasSRA)->RA_FILIAL))
			//Help alertando que nao carregou verbas para filial - SRA->RA_FILIAL - nao tenho acesso para AtuSx
			Exit
		Endif

		If Empty(cCentra) .Or. nTpImpre == 1
			fInfo(@aInfo, (cAliasSRA)->RA_FILIAL)
		EndIf		

  		If cFilQuebra != Replicate("!", FWGETTAMFILIAL) .And. ( Empty(cCentra) .Or. nTpImpre == 1 )
			fImpFil()    // Totaliza Filial
		EndIf
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Consiste Parametrizacao do Intervalo de Impressao            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If ((cAliasSRA)->RA_NOME   < cNomDe) .Or. ((cAliasSRA)->RA_NOME   > cNomAte)  .Or. ;
	   ((cAliasSRA)->RA_MAT    < cMatDe) .Or. ((cAliasSRA)->RA_MAT    > cMatAte)  .Or. ;
	   ((cAliasSRA)->RA_CC     < cCcDe ) .Or. ((cAliasSRA)->RA_CC     > cCcAte )  .Or. ;
	   ((cAliasSRA)->RA_FILIAL < cFilDe) .Or. ((cAliasSRA)->RA_FILIAL > cFilAte)
		fTestaTotal()
		Loop
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Consiste controle de acessos e filiais validas               ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !((cAliasSRA)->RA_FILIAL $ fValidFil()) .Or. !Eval(cAcessaSRA)
		fTestaTotal()
		Loop
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ponto de Entrada para desprezar funcionario caso retorne .T. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lGp050Fil	
		lRetPE := ExecBlock( "GP050FIL", .F., .F. )
		If ( ( ValType(lRetPE) == "L" ) .and. lRetPE )
			fTestaTotal() 
			Loop
		EndIf
	EndIf 
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Contera as verbas ja lidas - evitara que nao sejam duplicadas³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	
	aCodLido := {}  
	
	lIRMesAnt := .T.

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Carrega as transferencias do funcionario                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	fVerTransf( .F., aTransf , dDataDe, cEmpAnt, (cAliasSRA)->RA_FILIAL, (cAliasSRA)->RA_MAT )

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Processa movimento SRC / SRD                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	
	ProcMovime(aPerAberto, aPerFechado, aVerba)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Nao processa SRC/SRD se o funcionario tem rescisao          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea( "SRG" )
	If SRG->(dbSeek( (cAliasSRA)->(RA_FILIAL+RA_MAT) ))
		ProcRescisao()
	EndIf
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Procura no SRH Funcionarios em Ferias                        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !lPLR
		ProcFerias()
	EndIf
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Totalizador                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea((cAliasSRA))
	If	FTotAcumuladores(4,4) == 0
		fTestaTotal()
		Loop
	Endif
	fImpFun()
	fTestaTotal()
Enddo
IF nTipImp == 2
	oPrint:EndPage() 
ENDIF

Return()

Static Function fPosQuebra()
	oReport:SkipLine(2)
	oReport:FatLine()
	oReport:SkipLine(1)
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ChkDtPag Autor  ³RH      		         º Data ³  11/06/18   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Verifica se existem valor gerado no mês anterior a transfer_º±±
±±º          ³encia com data de pagamento posterior à mesma.              º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPER050			                                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/

Static Function ChkDtPag(cProcAux)

Local cQrAlias := GetNextAlias()
Local lRet := .F.

BeginSql alias cQrAlias                             
			
	SELECT SRD.R_E_C_N_O_	
    FROM  %table:SRD% SRD 
		       
    WHERE SRD.%notDel% AND 
    SRD.RD_FILIAL = %exp:(SRA->RA_FILIAL)% AND
    SRD.RD_MAT = %exp:(SRA->RA_MAT)% AND 
    SRD.RD_DATPGT BETWEEN %exp:(MV_PAR07)% AND %exp:(MV_PAR08)% AND
    SRD.RD_PROCES = %exp:(cProcAux)% AND 
    SRD.RD_PD = %exp:(aCodFol[66,1])%  
				
EndSql

If((cQrAlias)->(!Eof()))
	lRet := .T.
EndIf

(cQrAlias)->(dbCloseArea())

Return lRet 



Static Function fTrataVer(aVerbas)
Local cVerbas 	:= ""
Local nI 		:= 1

For nI := 1 To Len(aVerbas)
	cVerbas += "'" + aVerbas[nI][1] + "'," 
Next nI
If !Empty(cVerbas)
	cVerbas := subStr(cVerbas,1,Len(cVerbas)-1)   
EndIf  

Return cVerbas