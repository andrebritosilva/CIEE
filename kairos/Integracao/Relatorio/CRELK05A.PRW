#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} CRELK05A
//TODO Relatório Analitico de Repasse
@author andre.brito
@since 22/10/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/

User Function CRELK05A()      

Local cPerg        := PadR("CRELK05A", Len(SX1->X1_GRUPO))

//ValidPerg(cPerg)

oReport := ReportDef()  
oReport:PrintDialog()
	
Return

/*/{Protheus.doc} ReportDef
//TODO Definiçãoes do relatório
@author andre.brito
@since 22/10/2020
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function ReportDef()

Local oReport
Local oSessao1     
Local oSection2 
Local oSection3 
Local oSection4 

SET DATE FORMAT TO "dd/mm/yyyy"
SET CENTURY ON
SET DATE BRITISH

oReport := TReport():New("CRELK05A","Relatório Analitico Repasse",,{|oReport| PrintReport(oReport)},"Relatório - Analitico Repasse")
oReport:lParamPage := .F.   
oReport:SetLandscape(.T.)

oSessao1 := TRSection():New(oReport,"Analitico",{"TRB1"})

TRCell():New(oSessao1,"CPFEST"  ,'TRB1',"CPF"             ,,TamSX3("ZC6_CPFEST")[1] + 3  ,.F.)
TRCell():New(oSessao1,"NOMEST"  ,'TRB1',"Nome"            ,,40      ,.F.)
TRCell():New(oSessao1,"COMPET"  ,'TRB1',"Competencia"     ,,TamSX3("ZC6_COMPET")[1]      ,.F.)
TRCell():New(oSessao1,"IDCOTR"  ,'TRB1',"Contrato"        ,,TamSX3("ZC6_IDCOTR")[1]+2    ,.F.)
TRCell():New(oSessao1,"IDLCOT"  ,'TRB1',"Local Contrato"  ,,TamSX3("ZC6_IDLCOT")[1]      ,.F.)
TRCell():New(oSessao1,"NUMTIT"  ,'TRB1',"Num. Titulo"     ,,TamSX3("E1_NUM")[1]      ,.F.)
TRCell():New(oSessao1,"TCETCA"  ,'TRB1',"TCE/TCA"         ,,TamSX3("ZC6_TCETCA")[1]      ,.F.)
//TRCell():New(oSessao1,"QTDE"    ,'TRB1',"Qtd. TCE/TCA"    ,,TamSX3("ZC6_QTDE")[1]        ,.F.,,,,)
//TRCell():New(oSessao1,"VALOR"   ,'TRB1',"Vlr. Faturamento"           ,"@999,999,999.99",,,,,,"RIGHT")
TRCell():New(oSessao1,"UNICIEE" ,'TRB1',"Unidade CIEE"  ,,TamSX3("ZCN_DLOCAL")[1]      ,.F.)

oSection2 := TRSection():New(oReport,"Total",{"QTD"})

TRCell():New(oSection2,"QTD",,"Quantidade Aprendiz:",,40,,)

oSection3 := TRSection():New(oReport,"Total",{"UNIT"})

TRCell():New(oSection3,"UNIT",,"Valor Unitário:",,40,,)

oSection4 := TRSection():New(oReport,"Total",{"TOTRE"})

TRCell():New(oSection4,"TOTRE",,"Valor Total Repasse:",,40,,)

oSessao1:SetPageBreak(.T.)

Return oReport 

/*/{Protheus.doc} PrintReport
//TODO Descrição auto-gerada.
@author andre.brito
@since 22/10/2020
@version 1.0
@return ${return}, ${return_description}
@param oReport, object, descricao
@type function
/*/
Static Function PrintReport(oReport) 

Local aArea	   	  		  := GetArea() 
Local cQuery   	  		  := ""	 
Local cCampos             := ""
Local cQueryCmp           := ""
Local cTab                := ""
Local cCnpjBB             := AllTrim(GetMv('CI_CNPJBB'))
Local cCnpjCX             := AllTrim(GetMv('CI_CNPJCX'))
Local oSection2           := oReport:Section(2)
Local oSection3           := oReport:Section(3)
Local oSection4           := oReport:Section(4)
Local nTotApr             := 0
Local cCompet             := ZCC->ZCC_COMPET

	cTab := GetNextAlias()
	BeginSql alias cTab
		
		SELECT DISTINCT E1_PREFIXO, 
                E1_CLIENTE, 
                E1_LOJA, 
                E1_TIPO, 
                E1_NUM, 
                E1_XIDFATU, 
                ZC6_IDFATU, 
                ZC6_COMPET, 
                ZC6_QTDE, 
                ZC6_VALOR, 
                ZC6_VLRTOT, 
                ZC6_LOCCON, 
                ZC0_NOME, 
                ZC0_TIPAPR, 
                ZC6_IDCONT, 
                ZC6_CPFEST, 
                ZC6_NOMEST, 
                ZC6_IDCOTR, 
                ZC6_IDLCOT, 
                ZC6_TCETCA, 
                ZC6_VALOR, 
                ZCN_CODIGO, 
                ZCN_CIDADE, 
                ZCN_DLOCAL 
			FROM   ZC6020 ZC6 
			       JOIN ZC5020 ZC5 
			         ON ZC5_FILIAL = ZC6_FILIAL 
			            AND ZC5_IDFATU = ZC6_IDFATU 
			            AND ZC5.D_E_L_E_T_ = ' ' 
			       JOIN SE1020 SE1 
			         ON E1_FILORIG = ZC6_FILIAL 
			            AND E1_XIDFATU = ZC6_IDFATU 
			            AND E1_PEDIDO <> ' ' 
			            AND SE1.D_E_L_E_T_ = ' ' 
			       JOIN SA1020 SA1 
			         ON A1_FILIAL = E1_FILIAL 
			            AND A1_COD = E1_CLIENTE 
			            AND A1_LOJA = E1_LOJA 
			            AND SA1.D_E_L_E_T_ = ' ' 
			       JOIN ZC0020 ZC0 
			         ON ZC0_CODIGO = ZC6_IDCONT 
			            AND ZC0.D_E_L_E_T_ = ' ' 
			       JOIN SRA020 SRA 
			         ON RA_FILIAL = ZC6_FILIAL 
			            AND RA_CIC = ZC6_CPFEST 
			       JOIN ZC1020 ZC1 
			         ON ZC1_FILIAL = ' ' 
			            AND ZC1_CODIGO = E1_XIDCNT 
			            AND ZC1.D_E_L_E_T_ = ' ' 
			       JOIN ZC3020 ZC3 
			         ON ZC1_CODIGO = ZC3_IDCONT 
			            AND ZC3.D_E_L_E_T_ = ' ' 
			       JOIN ZCN020 ZCN 
			         ON ZCN_FILIAL = ' ' 
			            AND ZCN_CODIGO = ZC3_UNRESP 
			            AND ZCN.D_E_L_E_T_ = ' ' 
			WHERE  ZC6_COMPET = %Exp:cCompet%
			       AND ZC6_GERZC5 = 'S' 
			       AND ZC6.D_E_L_E_T_ = ' ' 
			       AND ZC0_TIPCON = '2' 
			       AND ( A1_CGC <> %exp:cCnpjBB% OR A1_CGC <> %exp:cCnpjCX% ) 
			ORDER  BY E1_NUM, 
			          ZC6_IDFATU, 
			          ZC6_COMPET 
	EndSql

	(cTab)->(DbGoTop())

oReport:SetMeter((cTab)->(RecCount()))
           
oReport:Section(1):Init()

While (cTab)->(!EOF())
  
	if oReport:Cancel()
		Exit
	Endif 
	
    nTotApr := nTotApr + 1
    
	oReport:IncMeter()  
	    
	oReport:Section(1):Cell("CPFEST"):SetBlock({|| ALLTRIM((cTab)->ZC6_CPFEST)}) 
	oReport:Section(1):Cell("NOMEST"):SetBlock({|| ALLTRIM((cTab)->ZC6_NOMEST) })
	oReport:Section(1):Cell("COMPET"):SetBlock({|| SubStr((cTab)->ZC6_COMPET,1,2) + "/" + SubStr((cTab)->ZC6_COMPET,3,6) }) 
	oReport:Section(1):Cell("IDCOTR"):SetBlock({|| (cTab)->ZC6_IDCOTR }) 
	oReport:Section(1):Cell("IDLCOT"):SetBlock({|| (cTab)->ZC6_IDLCOT }) 
	oReport:Section(1):Cell("NUMTIT"):SetBlock({|| Alltrim((cTab)->E1_NUM) })
	oReport:Section(1):Cell("TCETCA"):SetBlock({|| (cTab)->ZC6_TCETCA}) 
	//oReport:Section(1):Cell("QTDE"):SetBlock({|| Alltrim(Str((cTab)->ZC6_QTDE))}) 
	//oReport:Section(1):Cell("VALOR") :SetBlock({|| Alltrim(Transform((cTab)->ZC6_VALOR,"@E 999,999.99")) }) 
	oReport:Section(1):Cell("UNICIEE"):SetBlock({|| Alltrim((cTab)->ZCN_CODIGO) + " - " + Alltrim((cTab)->ZCN_CIDADE)})
	
	oReport:Section(1):PrintLine()
	
	(cTab)->(DBSKIP())  
	      
ENDDO 

oSection2:init()

oReport:Section(2):Cell("QTD"):SetBlock({|| Alltrim(TRANSFORM(nTotApr,"@!")) })

oSection2:PrintLine()

oSection3:init()

oReport:Section(3):Cell("UNIT"):SetBlock({|| Alltrim(TRANSFORM(GetMv('CI_VLRUFRM'), "@E 999,999,999.99"))   })

oSection3:PrintLine()

oSection4:init()

oReport:Section(4):Cell("TOTRE"):SetBlock({|| Alltrim(TRANSFORM(GetMv('CI_VLRUFRM') * nTotApr,"@E 999,999,999.99")) })

oSection4:PrintLine()

oSection2:Finish()
oSection3:Finish()
oSection4:Finish()

(cTab)->(DbCloseArea())

oReport:Section(1):Finish()
oSection2:Finish()

RestArea(aArea)

Return  

/*/{Protheus.doc} ValidPerg
//TODO Descrição auto-gerada.
@author andre.brito
@since 22/10/2020
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

//cPerg := PADR(cPerg,10)
cPerg := ""

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