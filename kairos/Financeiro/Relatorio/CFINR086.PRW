#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} CFINR01
//TODO Relatório de Integração - Ressarcimento Aprendiz
@author marcelo.moraes
@since 04/09/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/

User Function CFINR086(lRotina)      

local cPerg         := PadR("CFINR086", Len(SX1->X1_GRUPO)) 

private _lRotina    := lRotina
Private _cContrato  := ""
Private _cLocal     := "" 
Private _cCompeDe   := ""
Private _cCompeAte  := "" 

if _lRotina
    _cContrato  := MV_PAR01
    _cLocal     := MV_PAR02 
    _cCompeDe   := MV_PAR03
    _cCompeAte  := MV_PAR04
endif

ValidPerg(cPerg)

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
Static Function  ReportDef(cPerg) 

Local oReport
Local oSessao1     
SET DATE FORMAT TO "dd/mm/yyyy"
SET CENTURY ON
SET DATE BRITISH

if _lRotina
    cPerg := ""
else
    pergunte(cPerg,.F.) 
endif

//######################
//##Cria Objeto TReport#
//######################

oReport := TReport():New("CFINR086","Relatório de Integração - Ressarcimento Aprendiz",cPerg,{|oReport| PrintReport(oReport)},"Relatório de Integração - Ressarcimento Aprendiz")
oReport:lParamPage := .F.   
oReport:SetLandscape(.T.)

//###############
//##Cria Sessao1#
//###############

oSessao1 := TRSection():New(oReport,"Analítico",{"TRB1"})
oSessao1 :SetReadOnly()

TRCell():New(oSessao1,"CONTRATO" ,'TRB1',"Contrato",,TamSX3("ZCE_CODIGO")[1],.F.)
TRCell():New(oSessao1,"LOCAL" ,'TRB1',"Local",,TamSX3("ZCE_LOCCTR")[1],.F.)
TRCell():New(oSessao1,"PERIODO" ,'TRB1',"Periodo",,TamSX3("ZCE_PERIOD")[1],.F.)
TRCell():New(oSessao1,"CNPJ" ,'TRB1',"CNPJ",,14,.F.)
TRCell():New(oSessao1,"FATURA" ,'TRB1',"Int Repas?",,1,.F.)
TRCell():New(oSessao1,"STATUS" ,'TRB1',"Status Repasse",,95,.F.)
TRCell():New(oSessao1,"FATURACI" ,'TRB1',"Int CI?",,1,.F.)
TRCell():New(oSessao1,"STATUSCI" ,'TRB1',"Status CI",,95,.F.)

Return oReport 

/*/{Protheus.doc} PrintReport
//TODO Descrição auto-gerada
@author marcelo.moraes
@since 05/09/2018
@version 1.0
@return ${return}, ${return_description}
@param oReport, object, descricao
@type function
/*/
Static Function PrintReport(oReport) 

Local aArea	   	  		  := GetArea() 
local cPerg               := PadR("CFINR086", Len(SX1->X1_GRUPO)) 
Local cQuery   	  		  := "" 

if _lRotina
    pergunte(cPerg,.F.) 
    MV_PAR01 := _cContrato  
    MV_PAR02 := _cLocal      
    MV_PAR03 := _cCompeDe   
    MV_PAR04 := _cCompeAte  
endif

cQuery += " SELECT "
cQuery += " ZCE_CODIGO,ZCE_LOCCTR,ZCE_PERIOD,ZCE_CNPJ,ZCE_RAZAO,ZCE_FATURA,ZCE_STDESC,ZCE_FATUCI,ZCE_STDECI "
cQuery += " FROM "+RetSqlName("ZCE")
cQuery += " WHERE "
cQuery += " D_E_L_E_T_='' "
cQuery += " AND ZCE_FILIAL='"+xFilial("ZCE")+"' "
IF !Empty(MV_PAR01)
    cQuery += " AND ZCE_CODIGO='"+ALLTRIM(MV_PAR01)+"' "
endif
IF !Empty(MV_PAR02)
    cQuery += " AND ZCE_LOCCTR='"+ALLTRIM(MV_PAR02)+"' "
endif
cQuery += " AND ZCE_PERIOD BETWEEN '"+ALLTRIM(MV_PAR03)+"' AND '"+ALLTRIM(MV_PAR04)+"' "
cQuery += " ORDER BY "
cQuery += " ZCE_PERIOD,ZCE_CODIGO,ZCE_LOCCTR "

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

	oReport:Section(1):Cell("CONTRATO"):SetBlock({|| ALLTRIM(TRB1->ZCE_CODIGO) })  
	oReport:Section(1):Cell("LOCAL"):SetBlock({|| ALLTRIM(TRB1->ZCE_LOCCTR) })  
	oReport:Section(1):Cell("PERIODO"):SetBlock({|| ALLTRIM(TRB1->ZCE_PERIOD) }) 
	oReport:Section(1):Cell("CNPJ"):SetBlock({|| TRB1->ZCE_CNPJ }) 
	oReport:Section(1):Cell("FATURA"):SetBlock({|| IIF(ALLTRIM(TRB1->ZCE_FATURA)=="1","S","N") }) 
	oReport:Section(1):Cell("STATUS"):SetBlock({|| IIF(EMPTY(TRB1->ZCE_STDESC) .AND. ALLTRIM(TRB1->ZCE_FATURA)=="2","Integração do Repasse não processado",ALLTRIM(TRB1->ZCE_STDESC))}) 
	oReport:Section(1):Cell("FATURACI"):SetBlock({|| IIF(ALLTRIM(TRB1->ZCE_FATUCI)=="1","S","N") }) 
	oReport:Section(1):Cell("STATUSCI"):SetBlock({|| IIF(EMPTY(TRB1->ZCE_STDECI) .AND. (ALLTRIM(TRB1->ZCE_FATUCI)=="2" .OR. EMPTY(TRB1->ZCE_FATUCI)),"Integração da CI não processada",ALLTRIM(TRB1->ZCE_STDECI))}) 

	oReport:Section(1):PrintLine()
	
	TRB1->(DBSKIP())  
	      
ENDDO 

If Select("TRB1") > 0     
	TRB1->(DbCloseArea())
EndIf  

oReport:Section(1):Finish()

RestArea(aArea)

Return  

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

aAdd(aRegs,{cPerg,"01","Contrato de:","","","mv_ch1" ,"C",TamSX3("ZCE_CODIGO")[1],0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","ZC0","","","",""})
aAdd(aRegs,{cPerg,"02","Local de:   ","","","mv_ch2" ,"C",TamSX3("ZCE_LOCCTR")[1],0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","","ZC15","","","",""})
aAdd(aRegs,{cPerg,"03","Competência de:  ","","","mv_ch3" ,"C",TamSX3("ZCE_PERIOD")[1],0,0,"G","","MV_PAR03","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"04","Competência até: ","","","mv_ch4" ,"C",TamSX3("ZCE_PERIOD")[1],0,0,"G","","MV_PAR04","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

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


