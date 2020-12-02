#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} CFINR087
//TODO Relatório de Conferência Ressarcimento Aprendiz
@author marcelo.moraes
@since 04/09/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/

User Function CFINR087()      

local cPerg      := PadR("CFINR087", Len(SX1->X1_GRUPO)) 

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
oReport := TReport():New("CFINR087","Relatório de Conferência",cPerg,{|oReport| PrintReport(oReport)},"Relatório de Conferência")
oReport:lParamPage := .F.   
oReport:SetLandscape(.F.)

//###############
//##Cria Sessao1#
//###############

oSessao1 := TRSection():New(oReport,"Sintético",{"TRB1"})
oSessao1 :SetReadOnly()

TRCell():New(oSessao1,"PERIODO"      ,'TRB1',"Período",,TamSX3("ZCE_PERIOD")[1] + 1,.F.)
TRCell():New(oSessao1,"RAZAOSOC"     ,'TRB1',"Razão Social",,100,.F.)
TRCell():New(oSessao1,"CONTRATO"     ,'TRB1',"Contrato",,TamSX3("ZCE_CODIGO")[1],.F.)
TRCell():New(oSessao1,"LOCAL"        ,'TRB1',"Local",,TamSX3("ZCE_LOCCTR")[1],.F.)
TRCell():New(oSessao1,"QTDAPR"       ,'TRB1',"Qtd. Apr.",,04,,,,,"CENTER",,,.F.,,,)
TRCell():New(oSessao1,"CONTRIBUICAO" ,'TRB1',"C.I.","@E 999,999.99",14,,,,,"CENTER",,,.F.,,,)
TRCell():New(oSessao1,"TOTAL"        ,'TRB1',"Ressarcimento","@E 999,999.99",014,,,,,"CENTER",,,.F.,,,)
TRCell():New(oSessao1,"TOTRES"       ,'TRB1',"Total","@E 999,999.99",14,,,,,"CENTER",,,.F.,,,)

oSessao1:SetTotalInLine(.F.)
oSessao1:SetTotalText({|| Alltrim("TOTAIS")}) 

TRFunction():New(oSessao1:Cell("TOTAL"),/*cId*/,"SUM",/*oBreak*/,/*cTitle*/,"@E 999,999.99",/*uFormula*/,/*lEndSection*/,.F.,.T.)
TRFunction():New(oSessao1:Cell("QTDAPR"),/*cId*/,"SUM",/*oBreak*/,/*cTitle*/,,/*uFormula*/,/*lEndSection*/,.F.,.T.)
TRFunction():New(oSessao1:Cell("CONTRIBUICAO"),/*cId*/,"SUM",/*oBreak*/,/*cTitle*/,"@E 999,999.99",/*uFormula*/,/*lEndSection*/,.F.,.T.)
TRFunction():New(oSessao1:Cell("TOTRES"),/*cId*/,"SUM",/*oBreak*/,/*cTitle*/,"@E 999,999.99",/*uFormula*/,/*lEndSection*/,.F.,.T.)

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

cQuery += " SELECT "
cQuery += " ZCE_PERIOD as PERIODO, " 
cQuery += " ZCE_RAZAO as RAZAO_SOCIAL, " 
cQuery += " ZCE_CODIGO as CONTRATO, " 
cQuery += " ZCE_LOCCTR as LOCALIDADE, " 
cQuery += " COUNT(ZCE_MAT)       AS QTDAPR," 
cQuery += " SUM(ZCE_VLCI) as CONTRIBUICAO, "
cQuery += " SUM(ZCE_VLTRCI) as TOTAL, " 
cQuery += " SUM(ZCE_VLCI) + Sum(ZCE_VLTRCI) AS TOTRES"  
cQuery += " FROM "+RetSqlName("ZCE")
cQuery += " WHERE ZCE_PERIOD = '"+ALLTRIM(MV_PAR01)+"' "
cQuery += " AND D_E_L_E_T_ = '' "
cQuery += " GROUP BY ZCE_PERIOD, ZCE_RAZAO, ZCE_CODIGO, ZCE_LOCCTR "

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
  
  	oReport:Section(1):Cell("PERIODO"):SetBlock({|| SubStr(ALLTRIM(TRB1->PERIODO),5,6) + "/" + SubStr(ALLTRIM(TRB1->PERIODO),1,4) })  
	oReport:Section(1):Cell("RAZAOSOC"):SetBlock({|| ALLTRIM(TRB1->RAZAO_SOCIAL) }) 
	oReport:Section(1):Cell("CONTRATO"):SetBlock({|| ALLTRIM(TRB1->CONTRATO) }) 
	oReport:Section(1):Cell("LOCAL"):SetBlock({|| ALLTRIM(TRB1->LOCALIDADE) }) 
	oReport:Section(1):Cell("QTDAPR"):SetBlock({|| TRB1->QTDAPR }) 
	oReport:Section(1):Cell("CONTRIBUICAO"):SetBlock({|| TRB1->CONTRIBUICAO }) 
	oReport:Section(1):Cell("TOTAL"):SetBlock({|| TRB1->TOTAL }) 
	oReport:Section(1):Cell("TOTRES"):SetBlock({|| TRB1->TOTRES })
	
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
Local aRegs := {}
Local i,j

dbSelectArea("SX1")
dbSetOrder(1)

cPerg := PADR(cPerg,10)

aAdd(aRegs,{cPerg,"01","Competência: ","","","mv_ch1" ,"C",TamSX3("ZCE_PERIOD")[1],0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

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