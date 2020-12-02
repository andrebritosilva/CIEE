#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} CFINR01
//TODO Relatório de Inconsistencias
@author marcelo.moraes
@since 04/09/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/

User Function CFINR81(_dData)      

local cPerg      := PadR("CFINR81", Len(SX1->X1_GRUPO)) 
DEFAULT _dData   := ""
private dDataRef := _dData 

ValidPerg(cPerg)

if !Empty(dDataRef)
	cPerg := ""
endif

oReport := ReportDef(cPerg)  
oReport:PrintDialog()
	
RETURN

/*/{Protheus.doc} ReportDef
//TODO Definiçãoes do relatório
@author marcelo.moraes
@since 03/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function ReportDef(cPerg)

Local oReport
Local oSessao1     
SET DATE FORMAT TO "dd/mm/yyyy"
SET CENTURY ON
SET DATE BRITISH

pergunte(cPerg,.F.) 

//######################
//##Cria Objeto TReport#
//######################
//oReport := TReport():New("ZPFATR02","Comissões - Relatório Sintético",cPerg,{|oReport| PrintReport(oReport)},"Comissões - Relatório Sintético")

oReport := TReport():New("ZPFATR02","Relatório de Inconsistências",cPerg,{|oReport| PrintReport(oReport)},"Relatório - Inconsistências")
oReport:lParamPage := .F.   
oReport:SetLandscape(.T.)

//###############
//##Cria Sessao1#
//###############

oSessao1 := TRSection():New(oReport,"Sintético",{"TRB1"})
oSessao1 :SetReadOnly()

TRCell():New(oSessao1,"BANCO" ,'TRB1',"Banco",,3,.F.)
TRCell():New(oSessao1,"MATR" ,'TRB1',"Matr",,TamSX3("RA_MAT")[1],.F.)
TRCell():New(oSessao1,"NOME" ,'TRB1',"Nome",,TamSX3("RA_NOME")[1],.F.)
TRCell():New(oSessao1,"DATA" ,'TRB1',"Data",,10,.F.)
TRCell():New(oSessao1,"TITULO" ,'TRB1',"Título",,TamSX3("E2_NUM")[1],.F.)
TRCell():New(oSessao1,"CONTRATO" ,'TRB1',"Contrato",,TamSX3("RA_XIDCONT")[1],.F.)
TRCell():New(oSessao1,"LOCALCON" ,'TRB1',"Local Contr",,TamSX3("RA_XIDLOCT")[1],.F.)
TRCell():New(oSessao1,"IDFOLHA" ,'TRB1',"ID Folha",,TamSX3("RD_XIDFOL")[1],.F.)
TRCell():New(oSessao1,"CODINCON" ,'TRB1',"Cod Incon",,TamSX3("RD_XOCORRE")[1],.F.)
TRCell():New(oSessao1,"DESCINCON" ,'TRB1',"Inconsistência",,200,.F.)

Return oReport 

/*/{Protheus.doc} PrintReport
//TODO Descrição auto-gerada.
@author marcelo.moraes
@since 05/09/2018
@version 1.0
@return ${return}, ${return_description}
@param oReport, object, descricao
@type function
/*/
Static Function PrintReport(oReport) 

Local aArea	   	  		  := GetArea() 
Local cQuery   	  		  := "" 
//local cPagoSN  	  		  := ""
//local nAliqIRInd  		  := SuperGetMv("ZP_ALIQIRI",,15.00)
//local nAliqIRCom  		  := SuperGetMv("ZP_ALIQIRC",,1.5)
//local nAcrescimos 		  := 0
//local nDescontos  		  := 0
//local nAliqIRcms  		  := 0  
//local aDescontos		  := {}
//local nTOTPERIOD_DESCONTO := 0
//local nVCOMSIND_DESCONTO  := 0
//local nINDBRU_DESCONTO    := 0
//local nVIRCOMIS_DESCONTO  := 0
//local nVCOMISLIQ_DESCONTO := 0
//local nVIRIND_DESCONTO    := 0
//local nINDLIQ_DESCONTO    := 0

if !Empty(dDataRef)
	MV_PAR01 := ""
	MV_PAR02 := "" 
	MV_PAR03 := ""
	MV_PAR04 := dDataRef
	MV_PAR05 := dDataRef
endif

if Empty(MV_PAR04) .or. Empty(MV_PAR05)
	Alert("Preencha os parâmetros para informar Periodo De/Até:")
	return
endif 

cQuery += " SELECT " 
cQuery += " RA_MAT, RA_NOME, RA_XIDCONT, RA_XIDLOCT, RD_XIDFOL, RA_BCDEPSA, RD_XOCORRE, RD_DATPGT, RA_XDEATIV,RD_XNUMTIT, RD_DATPGT "
cQuery += " FROM "+RetSqlName("SRA")+" SRA "
cQuery += " INNER JOIN "+RetSqlName("SRD")+" SRD ON " 
cQuery += " 	SRD.D_E_L_E_T_='' AND "
cQuery += " 	RD_FILIAL=RA_FILIAL AND "
cQuery += "     RD_MAT=RA_MAT AND "
cQuery += "     RD_XIDCNT=RA_XIDCONT AND "
cQuery += "     RD_XIDLOC=RA_XIDLOCT AND "
cQuery += " 	RD_PD='J99' " 
cQuery += " WHERE " 
cQuery += " SRA.D_E_L_E_T_='' "
cQuery += " AND RA_XATIVO='N' "

if !Empty(MV_PAR01)
	cQuery += " AND RD_XIDFOL='"+ALLTRIM(MV_PAR01)+"' "
endif
if !Empty(MV_PAR02)
	cQuery += " AND RA_XIDCONT='"+ALLTRIM(MV_PAR02)+"' "
endif
if !Empty(MV_PAR03)
	cQuery += " AND RA_XIDLOCT='"+ALLTRIM(MV_PAR03)+"' "
ENDIF

cQuery += " AND RD_DATPGT BETWEEN '"+DTOS(MV_PAR04)+"' AND '"+DTOS(MV_PAR05)+"' "

cQuery += " UNION ALL "

cQuery += " SELECT " 

cQuery += " RA_MAT AS RA_MAT, RA_NOME AS RA_NOME, RA_XIDCONT AS RA_XIDLOCT, RA_XIDLOCT AS RD_XIDLOC, ZCV_IDFOL AS RD_XIDFOL, RA_BCDEPSA, ZCV_OCORRE AS RD_XOCORRE, ZCV_DATPGT AS RD_DATPGT, RA_XDEATIV,ZCV_NUMTIT AS RD_XNUMTIT, ZCV_DATPGT AS RD_DATPGT "
cQuery += " FROM "+RetSqlName("ZCV")+" ZCV "
cQuery += " INNER JOIN "+RetSqlName("SRA")+" SRA ON " 
cQuery += " 	SRA.D_E_L_E_T_='' AND "
cQuery += " 	ZCV_FILIAL=RA_FILIAL AND "
cQuery += "     ZCV_MAT=RA_MAT AND "
cQuery += "     ZCV_IDCNT=RA_XIDCONT AND "
cQuery += "     ZCV_IDLOC=RA_XIDLOCT"
cQuery += " WHERE " 
cQuery += " SRA.D_E_L_E_T_='' "
cQuery += " AND RA_XATIVO='N' "

if !Empty(MV_PAR01)
	cQuery += " AND ZCV_IDFOL='"+ALLTRIM(MV_PAR01)+"' "
endif
if !Empty(MV_PAR02)
	cQuery += " AND ZCV_IDCNT='"+ALLTRIM(MV_PAR02)+"' "
endif
if !Empty(MV_PAR03)
	cQuery += " AND RA_XIDLOCT='"+ALLTRIM(MV_PAR03)+"' "
ENDIF

cQuery += " AND ZCV_DATPGT BETWEEN '"+DTOS(MV_PAR04)+"' AND '"+DTOS(MV_PAR05)+"' "


cQuery += " ORDER BY RA_BCDEPSA "

If Select("TRB1") > 0     
	TRB1->(DbCloseArea())
EndIf  

cQuery := ChangeQuery(cQuery)

dbUseArea(.T.,'TOPCONN',TcGenQry(,,cQuery),'TRB1',.T.,.T.) 

oReport:SetMeter(TRB1->(RecCount()))
           
oReport:Section(1):Init()

While TRB1->(!EOF())
  
	if oReport:Cancel()
		Exit
	Endif 

	oReport:IncMeter()  

	oReport:Section(1):Cell("BANCO"):SetBlock({|| SUBSTR(ALLTRIM(TRB1->RA_BCDEPSA),1,3) })  
	oReport:Section(1):Cell("MATR"):SetBlock({|| ALLTRIM(TRB1->RA_MAT) })  
	oReport:Section(1):Cell("NOME"):SetBlock({|| ALLTRIM(TRB1->RA_NOME) }) 
	oReport:Section(1):Cell("DATA"):SetBlock({|| STOD(TRB1->RD_DATPGT) }) 
	oReport:Section(1):Cell("TITULO"):SetBlock({|| ALLTRIM(TRB1->RD_XNUMTIT) }) 
	oReport:Section(1):Cell("CONTRATO"):SetBlock({|| ALLTRIM(TRB1->RA_XIDCONT) }) 
	oReport:Section(1):Cell("LOCALCON"):SetBlock({|| ALLTRIM(TRB1->RA_XIDLOCT) }) 
	oReport:Section(1):Cell("IDFOLHA"):SetBlock({|| ALLTRIM(TRB1->RD_XIDFOL) }) 
	oReport:Section(1):Cell("CODINCON"):SetBlock({|| ALLTRIM(TRB1->RD_XOCORRE)}) 
	oReport:Section(1):Cell("DESCINCON"):SetBlock({|| DescOcor(SUBSTR(ALLTRIM(TRB1->RA_BCDEPSA),1,3),TRB1->RD_XOCORRE,TRB1->RA_XDEATIV) })
	
	oReport:Section(1):PrintLine()
	
	TRB1->(DBSKIP())  
	      
ENDDO 

If Select("TRB1") > 0     
	TRB1->(DbCloseArea())
EndIf  

oReport:Section(1):Finish()

RestArea(aArea)

Return  

/*/{Protheus.doc} DescOcor
//TODO Retorna a descrição das ocorrencias
@author marcelo.moraes
@since 05/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function DescOcor(cBanco,cStrOcor,cDescri)

local aArea    := GetArea()
local aAreaSEB := SEB->(GetArea())
local cRet     := ""
local aOcorr   := StrTokArr(cStrOcor, "|" ) 
local nCont    := 0
local cOcorr   := ""

if len(aOcorr) > 0
	for nCont=1 to len(aOcorr)
		cBanco := AVKEY(cBanco,"EB_BANCO")
		cOcorr := AVKEY(aOcorr[nCont],"EB_REFBAN")
		SEB->(dbSetOrder(1))
		If SEB->(DBSEEK(XFILIAL("SEB")+cBanco+cOcorr+"R"))
			cRet += aOcorr[nCont]+"-"+ALLTRIM(SEB->EB_DESCRI)+"/"
		else
			if !Empty(aOcorr[nCont])
				cRet += aOcorr[nCont]+"-"+"Cód ocorrên não cadastrado/"
			endif
		endif
	next
endif

//Se nao tiver codigo de ocorrencia, considera a ocorrencia cadastrada na SRA
if Empty(cRet)
	cRet := alltrim(cDescri)
endif

RestArea(aAreaSEB)
RestArea(aArea)

RETURN(cRet)

/*/{Protheus.doc} ValidPerg
//TODO Descrição auto-gerada.
@author marcelo.moraes
@since 05/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function ValidPerg(cPerg)

Local _aArea := getarea()
//Local aPerguntas := {}
Local aRegs := {}
Local i,j

dbSelectArea("SX1")
dbSetOrder(1)

cPerg := PADR(cPerg,10)

aAdd(aRegs,{cPerg,"01","ID Folha:      ","","","mv_ch1" ,"C",TamSX3("ZC2_IDFOLH")[1],0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"02","Contrato:      ","","","mv_ch2" ,"C",TamSX3("ZC0_CODIGO")[1],0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","","ZC0","","","",""})
aAdd(aRegs,{cPerg,"03","Local Contr:   ","","","mv_ch3" ,"C",TamSX3("ZC1_LOCCTR")[1],0,0,"G","","MV_PAR03","","","","","","","","","","","","","","","","","","","","","","","","","ZC14","","","",""})
aAdd(aRegs,{cPerg,"04","Periodo de:    ","","","mv_ch1" ,"D",08,0,0,"G","","MV_PAR04","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"05","Periodo até:   ","","","mv_ch2" ,"D",08,0,0,"G","","MV_PAR05","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

For i:=1 to Len(aRegs)
	If !dbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j <= Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock()
	Endif
Next

RestArea(_aArea)

Return()


