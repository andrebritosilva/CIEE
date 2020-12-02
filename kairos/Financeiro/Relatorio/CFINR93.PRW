#INCLUDE "PROTHEUS.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} CFINR93
Relatório Analítico CFINR93 - ZCE Ressarcimento Aprendiz Emprega

@author André Brito
@since 10/10/2020
@version P12
/*/
//-------------------------------------------------------------------

User Function CFINR93()      

Local cPerg      := PadR("CFINR93", Len(SX1->X1_GRUPO)) 

ValidPerg(cPerg)

oReport := ReportDef(cPerg)  
oReport:PrintDialog()
	
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} CFINR93
Relatório Analítico CFINR93 - Definição Relatório

@author André Brito
@since 10/10/2020
@version P12
/*/
//-------------------------------------------------------------------

Static Function ReportDef(cPerg)

Local oReport
Local oSessao1     
SET DATE FORMAT TO "dd/mm/yyyy"
SET CENTURY ON
SET DATE BRITISH

pergunte(cPerg,.F.) 

oReport := TReport():New("CFINR093","Relatório Analítico Conferência",cPerg,{|oReport| PrintReport(oReport)},"Relatório Analítico Conferência")
oReport:lParamPage := .F.   
oReport:SetLandscape(.F.)

oSessao1 := TRSection():New(oReport,"Analítico",{"TRB1"})
oSessao1 :SetReadOnly()

TRCell():New(oSessao1,"CNPJ"         ,'TRB1',"Cnpj"          ,,TamSX3("ZCE_CNPJ")[1],.F.)
TRCell():New(oSessao1,"RAZAO"        ,'TRB1',"Razão Social"  ,,55,.F.)
TRCell():New(oSessao1,"IDOBRA"       ,'TRB1',"ID Mão de Obra",,TamSX3("ZCE_IDMO")[1],.F.)
TRCell():New(oSessao1,"MATRICULA"    ,'TRB1',"Matricula"     ,,TamSX3("ZCE_MAT")[1],.F.)
TRCell():New(oSessao1,"NOME"         ,'TRB1',"Nome"          ,,TamSX3("ZCE_NOME")[1],,,,,,,,.F.,,,)
TRCell():New(oSessao1,"CPF"          ,'TRB1',"Cpf"           ,,TamSX3("ZCE_CPF")[1]+3,,,,,"CENTER",,,.F.,,,)
TRCell():New(oSessao1,"SALARIO"      ,'TRB1',"Salario"       ,"@E 999,999.99",TamSX3("ZCE_SALARI")[1],,,,,"CENTER",,,.F.,,,)
TRCell():New(oSessao1,"CONTRIBUICAO" ,'TRB1',"Contribuição"  ,"@E 999,999.99",TamSX3("ZCE_VLCI")[1],,,,,"CENTER",,,.F.,,,)
TRCell():New(oSessao1,"TOTALRESCI"   ,'TRB1',"Tot. Res. CI"  ,"@E 999,999.99",TamSX3("ZCE_VLTRCI")[1],,,,,"CENTER",,,.F.,,,)
TRCell():New(oSessao1,"PROVFERIAS"   ,'TRB1',"Prov. Férias"  ,"@E 999,999.99",TamSX3("ZCE_VLPFER")[1],,,,,"CENTER",,,.F.,,,)
TRCell():New(oSessao1,"PROVDECIMO"   ,'TRB1',"Prov. 13º"     ,"@E 999,999.99",TamSX3("ZCE_VLP13")[1],,,,,"CENTER",,,.F.,,,)

oSessao1:SetTotalInLine(.F.)
oSessao1:SetTotalText({|| Alltrim("TOTAIS")}) 

TRFunction():New(oSessao1:Cell("SALARIO"),/*cId*/,"SUM",/*oBreak*/,/*cTitle*/,"@E 999,999.99",/*uFormula*/,/*lEndSection*/,.F.,.T.)
TRFunction():New(oSessao1:Cell("CONTRIBUICAO"),/*cId*/,"SUM",/*oBreak*/,/*cTitle*/,,/*uFormula*/,/*lEndSection*/,.F.,.T.)
TRFunction():New(oSessao1:Cell("TOTALRESCI"),/*cId*/,"SUM",/*oBreak*/,/*cTitle*/,"@E 999,999.99",/*uFormula*/,/*lEndSection*/,.F.,.T.)
TRFunction():New(oSessao1:Cell("PROVFERIAS"),/*cId*/,"SUM",/*oBreak*/,/*cTitle*/,"@E 999,999.99",/*uFormula*/,/*lEndSection*/,.F.,.T.)
TRFunction():New(oSessao1:Cell("PROVDECIMO"),/*cId*/,"SUM",/*oBreak*/,/*cTitle*/,"@E 999,999.99",/*uFormula*/,/*lEndSection*/,.F.,.T.)

Return oReport 

//-------------------------------------------------------------------
/*/{Protheus.doc} CFINR93
Relatório Analítico CFINR93 - Montagem query e impressão do relatório

@author André Brito
@since 10/10/2020
@version P12
/*/
//-------------------------------------------------------------------

Static Function PrintReport(oReport) 

Local aArea	   	  		  := GetArea() 
Local cQuery   	  		  := "" 

cQuery += " SELECT "
cQuery += " ZCE_CNPJ as CNPJ, " 
cQuery += " ZCE_RAZAO as RAZAO, " 
cQuery += " ZCE_IDMO as IDOBRA, " 
cQuery += " ZCE_MAT as MATRICULA, "
cQuery += " ZCE_NOME as NOME, "
cQuery += " ZCE_CPF as CPF, "
cQuery += " ZCE_SALARI as SALARIO, "
cQuery += " ZCE_VLCI as CONTRIBUICAO, "
cQuery += " ZCE_VLTRCI as TOTALRESCI, "
cQuery += " ZCE_VLPFER as PROVFERIAS, "
cQuery += " ZCE_VLP13 as PROVDECIMO " 
cQuery += " FROM "+RetSqlName("ZCE")
cQuery += " WHERE ZCE_PERIOD = '"+ALLTRIM(MV_PAR01)+"' "
cQuery += " AND ZCE_IDMO = '"+ALLTRIM(MV_PAR02)+"' "
cQuery += " AND D_E_L_E_T_ = '' "
//cQuery += " GROUP BY ZCE_PERIOD, ZCE_RAZAO, ZCE_CODIGO, ZCE_LOCCTR,  ZCE_VLCI "

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
  
  	oReport:Section(1):Cell("CNPJ"):SetBlock({|| ALLTRIM(TRB1->CNPJ) })  
	oReport:Section(1):Cell("RAZAO"):SetBlock({|| ALLTRIM(TRB1->RAZAO) }) 
	oReport:Section(1):Cell("IDOBRA"):SetBlock({|| ALLTRIM(TRB1->IDOBRA) }) 
	oReport:Section(1):Cell("MATRICULA"):SetBlock({|| ALLTRIM(TRB1->MATRICULA) }) 
	oReport:Section(1):Cell("NOME"):SetBlock({|| Alltrim(TRB1->NOME) }) 
	oReport:Section(1):Cell("CPF"):SetBlock({|| Alltrim(TRANSFORM(TRB1->CPF,"@R 999.999.999-99")) }) 
	oReport:Section(1):Cell("SALARIO"):SetBlock({|| TRB1->SALARIO })
	oReport:Section(1):Cell("CONTRIBUICAO"):SetBlock({|| TRB1->CONTRIBUICAO })
	oReport:Section(1):Cell("TOTALRESCI"):SetBlock({|| TRB1->TOTALRESCI })
	oReport:Section(1):Cell("PROVFERIAS"):SetBlock({|| TRB1->PROVFERIAS })
	oReport:Section(1):Cell("PROVDECIMO"):SetBlock({|| TRB1->PROVDECIMO })
	
	oReport:Section(1):PrintLine()
	
	TRB1->(DBSKIP())  
	      
ENDDO 

If Select("TRB1") > 0     
	TRB1->(DbCloseArea())
EndIf  

oReport:Section(1):Finish()

RestArea(aArea)

Return  

//-------------------------------------------------------------------
/*/{Protheus.doc} CFINR93
Relatório Analítico CFINR93 - Validação pergunte CFINR93

@author André Brito
@since 10/10/2020
@version P12
/*/
//-------------------------------------------------------------------

Static Function ValidPerg(cPerg)

Local _aArea := getarea()
Local aRegs  := {}
Local i,j

dbSelectArea("SX1")
dbSetOrder(1)

cPerg := PADR(cPerg,10)

aAdd(aRegs,{cPerg,"01","Competência: ","","","mv_ch1" ,"C",TamSX3("ZCE_PERIOD")[1],0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"02","Mão de Obra: ","","","mv_ch1" ,"C",TamSX3("ZCE_IDMO")[1],0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

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