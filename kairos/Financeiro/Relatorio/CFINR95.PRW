#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} CFINR95
//TODO Relatório de Inconsistencias
@author andre.brito
@since 16/10/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/

User Function CFINR95()      

Local cPerg        := PadR("CFINR95", Len(SX1->X1_GRUPO))

ValidPerg(cPerg)

oReport := ReportDef(cPerg)  
oReport:PrintDialog()
	
Return

/*/{Protheus.doc} ReportDef
//TODO Definiçãoes do relatório
@author andre.brito
@since 16/10/2020
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

oReport := TReport():New("CFINR95","Relatório de Inconsistências Contas Receber",cPerg,{|oReport| PrintReport(oReport)},"Relatório - Inconsistências")
oReport:lParamPage := .F.   
oReport:SetLandscape(.T.)

oSessao1 := TRSection():New(oReport,"Sintético",{"TRB1"})

TRCell():New(oSessao1,"NUMERO"     ,'TRB1',"Numero"         ,,TamSX3("E1_NUM")[1]       ,.F.)
TRCell():New(oSessao1,"TIPO"       ,'TRB1',"Tipo"           ,,TamSX3("E1_TIPO")[1]      ,.F.)
TRCell():New(oSessao1,"PARCELA"    ,'TRB1',"Parcela"        ,,TamSX3("E1_PARCELA")[1]   ,.F.)
TRCell():New(oSessao1,"EMISSAO"    ,'TRB1',"Emissao"        ,,TamSX3("E1_EMISSAO")[1]+2 ,.F.)
TRCell():New(oSessao1,"VENCIMENTO" ,'TRB1',"Vencimento"     ,,TamSX3("E1_VENCTO")[1]    ,.F.)
TRCell():New(oSessao1,"VENCREA"    ,'TRB1',"Venc. Real"     ,,TamSX3("E1_VENCREA")[1]   ,.F.)
TRCell():New(oSessao1,"COMPETENCIA",'TRB1',"Competencia"    ,,TamSX3("E1_XCOMPET")[1]   ,.F.)
TRCell():New(oSessao1,"NUMBOR"     ,'TRB1',"Num. Bordero"   ,,TamSX3("E1_NUMBOR")[1]    ,.F.)
TRCell():New(oSessao1,"VALOR"      ,'TRB1',"Valor"          ,"@E 999,999,999.99",TamSX3("E1_VALOR")[1]     ,,,,,"RIGHT")
TRCell():New(oSessao1,"CONTRATO"   ,'TRB1',"Contrato"       ,,TamSX3("E1_XIDCNT")[1]    ,,,,,)
TRCell():New(oSessao1,"LOCAL"      ,'TRB1',"Local"          ,,TamSX3("E1_XIDLOC")[1]    ,.F.)
TRCell():New(oSessao1,"BANCO"      ,'TRB1',"Banco"          ,,TamSX3("FI0_BCO")[1]      ,.F.)
TRCell():New(oSessao1,"XNUMBCO"    ,'TRB1',"Nosso Numero"   ,,18                        ,.F.)
TRCell():New(oSessao1,"MOTIVO"     ,'TRB1',"Cod. Motivo"    ,,TamSX3("FI1_XMOTIV")[1]   ,.F.)
TRCell():New(oSessao1,"DESCINCON"  ,'TRB1',"Inconsistência" ,,TamSX3("FI1_XDESMO")[1]   ,.F.)

Return oReport 

/*/{Protheus.doc} PrintReport
//TODO Descrição auto-gerada.
@author andre.brito
@since 16/10/2020
@version 1.0
@return ${return}, ${return_description}
@param oReport, object, descricao
@type function
/*/
Static Function PrintReport(oReport) 

Local aArea	   	  		  := GetArea() 
Local cQuery   	  		  := ""	 
Local cCampos             := ""
Local aCampos             := {}
Local cQueryCmp           := ""

cCampos   := "E1_NUM, E1_VALOR, E1_NUMBOR, E1_XCOMPET, E1_TIPO,E1_VENCTO,E1_VENCREA, E1_EMISSAO, E1_PARCELA, E1_XIDLOC, E1_XIDCNT, E1_NATUREZ, E1_PORTADO, E1_NUMBCO, E1_AGEDEP, E1_CONTA, E1_XSUBCTA, FI1_OCORB, FI1_OCORS, FI1_XMOTIV, FI1_XDESMO, FI0_ARQ, FI0_DTPRC, FI0_HRPRC, FI0_BCO, FI0_AGE, FI0_CTA, FI0_USU "
aCampos   := strtokarr(cCampos, ",")
cQueryCmp := cCampos

cQuery := "SELECT " + cCampos + ""
cQuery += " FROM " + retSqlName("FI1") + " FI1 "
cQuery += " INNER JOIN " + retSqlName("FI0") +  " FI0 " 
cQuery += " ON FI0_FILIAL = '    ' " 
cQuery += " AND FI0_IDARQ = FI1_IDARQ " 
cQuery += " AND FI0.D_E_L_E_T_ = ' ' " 
cQuery += " INNER JOIN " + retSqlName("SE1") + " SE1 "  
cQuery += " ON E1_FILIAL = '    ' " 
cQuery += " AND E1_IDCNAB = FI1_IDTIT " 
cQuery += " AND SE1.D_E_L_E_T_ = ' ' " 
cQuery += " INNER JOIN " + retSqlName("SEB") + " SEB " 
cQuery += " ON EB_FILIAL = '    ' "
cQuery += " AND EB_BANCO = FI0_BCO "
cQuery += " AND EB_REFBAN = FI1_OCORB " 
cQuery += " AND EB_TIPO = 'R' " 
cQuery += " AND SEB.D_E_L_E_T_ = ' ' " 
cQuery += " WHERE  FI1_FILIAL = '    ' "
cQuery += " AND FI1.FI1_OCORB = '03'"  

If !Empty(mv_par01)
	cQuery += " AND E1_XIDCNT = '" + mv_par01 + "'"  
EndIf

If !Empty(mv_par02)
	cQuery += " AND E1_XIDLOC = '" + mv_par02 + "'"   
EndIf

If !Empty(mv_par03)
	cQuery += " AND FI0.FI0_BCO = '" + mv_par03 + "'"   
EndIf

If !Empty(mv_par04)
	cQuery += " AND FI1.FI1_XMOTIV = '" + mv_par04 + "'"   
EndIf

cQuery += " AND FI1.D_E_L_E_T_ = ' ' " 
cQuery += " GROUP BY " + cCampos + "" 
          
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),'TRB1',.T.,.T.)

oReport:SetMeter(TRB1->(RecCount()))
           
oReport:Section(1):Init()

While TRB1->(!EOF())
  
	if oReport:Cancel()
		Exit
	Endif 

	oReport:IncMeter()  
	    
	oReport:Section(1):Cell("NUMERO"):SetBlock({|| ALLTRIM(TRB1->E1_NUM) }) 
	oReport:Section(1):Cell("TIPO"):SetBlock({|| ALLTRIM(TRB1->E1_TIPO) })
	oReport:Section(1):Cell("PARCELA"):SetBlock({||ALLTRIM(TRB1->E1_PARCELA) }) 
	oReport:Section(1):Cell("EMISSAO"):SetBlock({|| STOD(ALLTRIM(TRB1->E1_EMISSAO)) }) 
	oReport:Section(1):Cell("VENCIMENTO"):SetBlock({|| STOD(ALLTRIM(TRB1->E1_VENCTO)) }) 
	oReport:Section(1):Cell("VENCREA"):SetBlock({|| STOD(ALLTRIM(TRB1->E1_VENCREA)) })
	oReport:Section(1):Cell("COMPETENCIA"):SetBlock({|| SubStr(ALLTRIM(TRB1->E1_XCOMPET),1,2) + "/" + SubStr(ALLTRIM(TRB1->E1_XCOMPET),3,4) })  
	oReport:Section(1):Cell("NUMBOR"):SetBlock({|| ALLTRIM(TRB1->E1_NUMBOR) }) 
	oReport:Section(1):Cell("VALOR"):SetBlock({|| TRB1->E1_VALOR }) 
	oReport:Section(1):Cell("CONTRATO"):SetBlock({|| ALLTRIM(TRB1->E1_XIDCNT)}) 
	oReport:Section(1):Cell("LOCAL"):SetBlock({|| ALLTRIM(TRB1->E1_XIDLOC) }) 
	oReport:Section(1):Cell("BANCO"):SetBlock({|| ALLTRIM(TRB1->FI0_BCO) }) 
	oReport:Section(1):Cell("XNUMBCO"):SetBlock({|| U_RetNossNum(TRB1->E1_NUMBCO,TRB1->E1_PORTADO,TRB1->E1_AGEDEP,TRB1->E1_CONTA,TRB1->E1_XSUBCTA)})
	oReport:Section(1):Cell("MOTIVO"):SetBlock({|| ALLTRIM(TRB1->FI1_XMOTIV)})  
	oReport:Section(1):Cell("DESCINCON"):SetBlock({|| ALLTRIM(TRB1->FI1_XDESMO) })
	
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
@author andre.brito
@since 16/10/2020
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function ValidPerg(cPerg)

Local _aArea := GetArea()
Local aRegs  := {}
Local i,j

dbSelectArea("SX1")
dbSetOrder(1)

cPerg := PADR(cPerg,10)

aAdd(aRegs,{cPerg,"01","Contrato:      ","","","mv_ch1" ,"C",TamSX3("ZC0_CODIGO")[1],0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","ZC0","","","",""})
aAdd(aRegs,{cPerg,"02","Local Contr:   ","","","mv_ch2" ,"C",TamSX3("ZC1_LOCCTR")[1],0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","","ZC17","","","",""})
aAdd(aRegs,{cPerg,"03","Banco:   "      ,"","","mv_ch3" ,"C",TamSX3("A6_COD")[1],0,0,"G","","MV_PAR03","","","","","","","","","","","","","","","","","","","","","","","","","SZ1","","","",""})
aAdd(aRegs,{cPerg,"04","Ocorrencia:   " ,"","","mv_ch4" ,"C",TamSX3("EB_REFBAN")[1],0,0,"G","","MV_PAR04","","","","","","","","","","","","","","","","","","","","","","","","","SEB2","","","",""})

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

User function RetNossNum(cNumBco,cPortado,cAGEDEP,cConta,cXSUBCTA)

Local aArea		:= GetArea()
Local aAreaSEE  := SEE->(GetArea())
Local cRet      := ""
local cDig      := ""
local cCart     := ""
local cNossoNum := ""

if !Empty(cNumBco)

	cNossoNum  := STRZERO(VAL(cNumBco),11)                             

	cDig := U_MOD11("09"+STRZERO(VAL(cNumBco),11)) 

	//Busca carteira
	dbSelectArea("SEE")   // Tabela de Bancos 
	dbSetOrder(1)	
	If SEE->(DbSeek(xfilial("SEE") + AvKey(cPortado,"EE_CODIGO") + AvKey(cAGEDEP,"EE_AGENCIA") + AvKey(cConta,"EE_CONTA") + AvKey(cXSUBCTA,"EE_SUBCTA"))) 
		cCart := SEE->EE_CODCART
	endif
  
	cRet := cCart + "-" + cNossoNum + "-" + cDig

endif

RestArea(aAreaSEE)
RestArea(aArea)

Return cRet