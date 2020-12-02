#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} CFINR94
//TODO Relatório de Inconsistencias
@author andre.brito
@since 16/10/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/

User Function CFINR94()      

Local cPerg        := PadR("CFINR94", Len(SX1->X1_GRUPO)) 

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

oReport := TReport():New("CFINR94","Relatório de Inconsistências - CFINA100 ",cPerg,{|oReport| PrintReport(oReport)},"Relatório - Inconsistências")
oReport:lParamPage := .F.   
oReport:SetLandscape(.T.)

oSessao1 := TRSection():New(oReport,"Sintético",{"TRB1"})

TRCell():New(oSessao1,"NOME"     ,'TRB1',"Nome"          ,,TamSX3("RA_NOME")[1] + 10   ,.F.)
TRCell():New(oSessao1,"CPF"      ,'TRB1',"Cpf"           ,,20                          ,.F.)
TRCell():New(oSessao1,"DATA"     ,'TRB1',"Periodo"       ,,15                          ,.F.)
TRCell():New(oSessao1,"TITULO"   ,'TRB1',"Título"        ,,TamSX3("E2_NUM")[1] + 5     ,.F.)
TRCell():New(oSessao1,"CONTRATO" ,'TRB1',"Contrato"      ,,TamSX3("RA_XIDCONT")[1] + 2 ,.F.)
TRCell():New(oSessao1,"LOCALCON" ,'TRB1',"Local Contr"   ,,TamSX3("RA_XIDLOCT")[1] + 2 ,.F.)
TRCell():New(oSessao1,"IDFOLHA"  ,'TRB1',"ID Folha"      ,,TamSX3("ZCV_IDFOL")[1] + 2  ,.F.)
TRCell():New(oSessao1,"BANCO"    ,'TRB1',"Banco"         ,,3                           ,.F.)
TRCell():New(oSessao1,"CONTA"    ,'TRB1',"Conta"         ,,15                          ,.F.)
TRCell():New(oSessao1,"DIGITO"   ,'TRB1',"Digito"        ,,01                          ,.F.)
TRCell():New(oSessao1,"CODINCON" ,'TRB1',"Cod Incon"     ,,TamSX3("ZCV_OCORRE")[1] + 2 ,.F.)
TRCell():New(oSessao1,"DESCINCON",'TRB1',"Inconsistência",,150                         ,.F.)

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

cCampos   := "RA_FILIAL,RA_XATIVO,ZCV_OCORRE,ZCV_NUMTIT,RA_MAT,RA_XOCOREN, RA_NOME,RA_CIC,RA_XIDCONT,RA_XIDLOCT,ZCV_DATPGT,RA_XDEATIV,RA_BCDEPSA,RA_XDIGAG,RA_CTDEPSA,RA_XDIGCON,RA_XSTATOC,RQ_XATIVO,ZCV_IDFOL,ZCV_COMPET,RQ_XVALIBC,RQ_NOME,RQ_ORDEM,RQ_SEQUENC,RQ_BCDEPBE,RQ_CTDEPBE,RA_VLDBAN,EB_DESCRI"
aCampos   := strtokarr(cCampos, ",")
cQueryCmp := cCampos

cQueryCmp := strTran(cQueryCmp, ",RA_VLDBAN", "")

cQuery += "SELECT DISTINCT " + cQueryCmp + CRLF 
cQuery += ", CASE WHEN EB.EB_BANCO IS NULL THEN '1' WHEN RTRIM(LTRIM(EB.EB_BANCO)) = '' THEN '1' ELSE '' END AS RA_VLDBAN " + CRLF
cQuery += "FROM " + retSqlName("ZCV") + " ZCV " + CRLF
cQuery += "INNER JOIN " + retSqlName("SRA") + " RA ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "LEFT JOIN " + retSqlName("SRQ") + " RQ ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RA.RA_BCDEPSA,1,3) AND ZCV.ZCV_OCORRE LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "WHERE ZCV.ZCV_FILIAL = '" + xFilial("ZCV") + "' " + CRLF
cQuery += "AND ZCV.ZCV_OCORRE != '" + space(tamSx3("ZCV_OCORRE")[1]) + "' " + CRLF
cQuery += "AND EB.EB_OCORR = '03' " + CRLF

If !Empty(mv_par01)
	cQuery += "AND ZCV.ZCV_IDFOL = '" + Alltrim(mv_par01) + "' " + CRLF
EndIf
If !Empty(mv_par02)
	cQuery += "AND RA.RA_XIDCONT = '" + Alltrim(mv_par02) + "' " + CRLF
EndIf
If !Empty(mv_par03)
	cQuery += "AND RA.RA_XIDLOCT = '" + Alltrim(mv_par03) + "' " + CRLF
EndIf
If !Empty(mv_par04)
	cQuery += "AND SUBSTRING(RA.RA_BCDEPSA,1,3) = '" + Alltrim(mv_par04) + "' " + CRLF
EndIf
If !Empty(mv_par05)
	cQuery += "AND EB.EB_REFBAN = '" + Alltrim(mv_par05) + "' " + CRLF
EndIf

cQuery += "AND ZCV.D_E_L_E_T_ = ' ' " + CRLF

cQuery += "UNION ALL " + CRLF

cQuery += "SELECT DISTINCT " + cQueryCmp + CRLF
cQuery += ", CASE WHEN EB.EB_BANCO IS NULL THEN '1' ELSE '' END AS RA_VLDBAN " + CRLF
cQuery += "FROM " + retSqlName("SRA") + " RA " + CRLF
cQuery += "LEFT JOIN " + retSqlName("ZCV") + " ZCV ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND ZCV.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "LEFT JOIN " + retSqlName("SRQ") + " RQ ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RA.RA_BCDEPSA,1,3) AND RA.RA_XOCOREN LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "WHERE RA.RA_FILIAL = '" + xFilial("SRA") + "' " + CRLF
cQuery += "AND RA.RA_XATIVO = 'N' " + CRLF
cQuery += "AND RA.RA_XOCOREN != '          ' " + CRLF
cQuery += "AND EB.EB_OCORR = '03' " + CRLF

If !Empty(mv_par01)
	cQuery += "AND ZCV.ZCV_IDFOL = '" + Alltrim(mv_par01) + "' " + CRLF
EndIf
If !Empty(mv_par02)
	cQuery += "AND RA.RA_XIDCONT = '" + Alltrim(mv_par02) + "' " + CRLF
EndIf
If !Empty(mv_par03)
	cQuery += "AND RA.RA_XIDLOCT = '" + Alltrim(mv_par03) + "' " + CRLF
EndIf
If !Empty(mv_par04)
	cQuery += "AND SUBSTRING(RA.RA_BCDEPSA,1,3) = '" + Alltrim(mv_par04) + "' " + CRLF
EndIf
If !Empty(mv_par05)
	cQuery += "AND EB.EB_REFBAN = '" + Alltrim(mv_par05) + "' " + CRLF
EndIf

cQuery += "AND RA.D_E_L_E_T_ = ' ' " + CRLF

cQuery += "UNION ALL " + CRLF

cQuery += "SELECT DISTINCT " + cQueryCmp + CRLF
cQuery += ", CASE WHEN EB.EB_BANCO IS NULL THEN '1' ELSE '' END AS RA_VLDBAN " + CRLF
cQuery += "FROM " + retSqlName("SRQ") + " RQ " + CRLF
cQuery += "INNER JOIN " + retSqlName("SRA") + " RA ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "LEFT JOIN " + retSqlName("ZCV") + " ZCV ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND ZCV.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RQ.RQ_BCDEPBE,1,3) AND RQ.RQ_XOCOREN LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "WHERE RQ.RQ_FILIAL = '" + xFilial("SRQ") + "' " + CRLF
cQuery += "AND RQ.RQ_XOCOREN != '          ' " + CRLF
cQuery += "AND RQ.RQ_XATIVO = 'N' " + CRLF
cQuery += "AND EB.EB_OCORR = '03' " + CRLF

If !Empty(mv_par01)
	cQuery += "AND ZCV.ZCV_IDFOL = '" + Alltrim(mv_par01) + "' " + CRLF
EndIf
If !Empty(mv_par02)
	cQuery += "AND RA.RA_XIDCONT = '" + Alltrim(mv_par02) + "' " + CRLF
EndIf
If !Empty(mv_par03)
	cQuery += "AND RA.RA_XIDLOCT = '" + Alltrim(mv_par03) + "' " + CRLF
EndIf
If !Empty(mv_par04)
	cQuery += "AND SUBSTRING(RA.RA_BCDEPSA,1,3) = '" + Alltrim(mv_par04) + "' " + CRLF
EndIf
If !Empty(mv_par05)
	cQuery += "AND EB.EB_REFBAN = '" + Alltrim(mv_par05) + "' " + CRLF
EndIf

cQuery += "AND RQ.D_E_L_E_T_ = ' ' " + CRLF

cQuery += "UNION ALL " + CRLF

cQuery += "SELECT DISTINCT " + cQueryCmp + CRLF
cQuery += ", '1' AS RA_VLDBAN  " + CRLF
cQuery += "FROM " + retSqlName("SRA") + " RA  " + CRLF
cQuery += "LEFT JOIN " + retSqlName("ZCV") + " ZCV ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND ZCV.D_E_L_E_T_ = ' '  " + CRLF
cQuery += "LEFT JOIN " + retSqlName("SRQ") + " RQ ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' '  " + CRLF
cQuery += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RA.RA_BCDEPSA,1,3) AND RA.RA_XOCOREN LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.EB_OCORR = '03' AND EB.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "WHERE RA.RA_FILIAL = '" + xFilial("SRA") + "'  " + CRLF
cQuery += "AND RA.RA_XATIVO = 'N'  " + CRLF
cQuery += "AND RA.RA_XOCOREN != '          ' " + CRLF

If !Empty(mv_par01)
	cQuery += "AND ZCV.ZCV_IDFOL = '" + Alltrim(mv_par01) + "' " + CRLF
EndIf
If !Empty(mv_par02)
	cQuery += "AND RA.RA_XIDCONT = '" + Alltrim(mv_par02) + "' " + CRLF
EndIf
If !Empty(mv_par03)
	cQuery += "AND RA.RA_XIDLOCT = '" + Alltrim(mv_par03) + "' " + CRLF
EndIf
If !Empty(mv_par04)
	cQuery += "AND SUBSTRING(RA.RA_BCDEPSA,1,3) = '" + Alltrim(mv_par04) + "' " + CRLF
EndIf
If !Empty(mv_par05)
	cQuery += "AND EB.EB_REFBAN = '" + Alltrim(mv_par05) + "' " + CRLF
EndIf

cQuery += "AND NOT EXISTS(SELECT EB2.EB_BANCO FROM " + retSqlName("SEB") + " EB2 WHERE EB2.EB_BANCO = SUBSTRING(RA.RA_BCDEPSA,1,3) AND RA.RA_XOCOREN LIKE ('%' + RTRIM(LTRIM(EB2.EB_REFBAN)) + '%') AND EB2.D_E_L_E_T_ = ' ' ) " + CRLF
cQuery += "AND RA.D_E_L_E_T_ = ' ' " + CRLF

cQuery += "UNION ALL " + CRLF

cQuery += "SELECT DISTINCT " + cQueryCmp + CRLF
cQuery += ", CASE WHEN EB.EB_BANCO IS NULL THEN '2' ELSE '' END AS RA_VLDBAN " + CRLF
cQuery += "FROM " + retSqlName("SRA") + " RA " + CRLF
cQuery += "LEFT JOIN " + retSqlName("ZCV") + " ZCV ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND ZCV.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "LEFT JOIN " + retSqlName("SRQ") + " RQ ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RA.RA_BCDEPSA,1,3) AND RA.RA_XOCOREN LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "WHERE RA.RA_FILIAL = '" + xFilial("SRA") + "' " + CRLF
cQuery += "AND RA_BCDEPSA != '' AND RA.RA_CTDEPSA != '' AND RA.RA_XATIVO = 'N' " + CRLF
cQuery += "AND RA.RA_XOCOREN = '' AND RA_XORDPGT = 'N' " + CRLF

If !Empty(mv_par01)
	cQuery += "AND ZCV.ZCV_IDFOL = '" + Alltrim(mv_par01) + "' " + CRLF
EndIf
If !Empty(mv_par02)
	cQuery += "AND RA.RA_XIDCONT = '" + Alltrim(mv_par02) + "' " + CRLF
EndIf
If !Empty(mv_par03)
	cQuery += "AND RA.RA_XIDLOCT = '" + Alltrim(mv_par03) + "' " + CRLF
EndIf
If !Empty(mv_par04)
	cQuery += "AND SUBSTRING(RA.RA_BCDEPSA,1,3)= '" + Alltrim(mv_par04) + "' " + CRLF
EndIf
If !Empty(mv_par05)
	cQuery += "AND EB.EB_REFBAN = '" + Alltrim(mv_par05) + "' " + CRLF
EndIf

cQuery += " " + CRLF
cQuery += "AND RA.D_E_L_E_T_ = ' ' " + CRLF

cQuery += "UNION ALL " + CRLF

cQuery += "SELECT DISTINCT " + cQueryCmp + CRLF
cQuery += ", '3' AS RA_VLDBAN " + CRLF
cQuery += "FROM " + retSqlName("SRA") + " RA " + CRLF
cQuery += "LEFT JOIN " + retSqlName("ZCV") + " ZCV ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND ZCV.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "LEFT JOIN " + retSqlName("SRQ") + " RQ ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RA.RA_BCDEPSA,1,3) AND RA.RA_XOCOREN LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.D_E_L_E_T_ = ' ' " + CRLF
cQuery += "WHERE RA.RA_FILIAL = '" + xFilial("SRA") + "' " + CRLF
cQuery += "AND RA_BCDEPSA != '' " + CRLF
cQuery += "AND EB.EB_BANCO IS NULL AND RA.RA_CTDEPSA = '' AND RA_XORDPGT = 'N' AND RA.RA_XOCOREN = '          ' " + CRLF

If !Empty(mv_par01)
	cQuery += "AND ZCV.ZCV_IDFOL = '" + Alltrim(mv_par01) + "' " + CRLF
EndIf
If !Empty(mv_par02)
	cQuery += "AND RA.RA_XIDCONT = '" + Alltrim(mv_par02) + "' " + CRLF
EndIf
If !Empty(mv_par03)
	cQuery += "AND RA.RA_XIDLOCT = '" + Alltrim(mv_par03) + "' " + CRLF
EndIf
If !Empty(mv_par04)
	cQuery += "AND SUBSTRING(RA.RA_BCDEPSA,1,3) = '" + Alltrim(mv_par04) + "' " + CRLF
EndIf
If !Empty(mv_par05)
	cQuery += "AND EB.EB_REFBAN = '" + Alltrim(mv_par05) + "' " + CRLF
EndIf
cQuery += "  " + CRLF
cQuery += "AND RA.D_E_L_E_T_ = ' ' " + CRLF

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),'TRB1',.T.,.T.)

oReport:SetMeter(TRB1->(RecCount()))
           
oReport:Section(1):Init()

While TRB1->(!EOF())
  
	if oReport:Cancel()
		Exit
	Endif 

	oReport:IncMeter()  
	    
	oReport:Section(1):Cell("NOME"):SetBlock({|| ALLTRIM(TRB1->RA_NOME) }) 
	oReport:Section(1):Cell("CPF"):SetBlock({|| ALLTRIM(TRB1->RA_CIC) })
	oReport:Section(1):Cell("DATA"):SetBlock({|| SubStr(ALLTRIM(TRB1->ZCV_COMPET),5,6) + "/" + SubStr(ALLTRIM(TRB1->ZCV_COMPET),1,4) }) 
	oReport:Section(1):Cell("TITULO"):SetBlock({|| ALLTRIM(TRB1->ZCV_NUMTIT) }) 
	oReport:Section(1):Cell("CONTRATO"):SetBlock({|| ALLTRIM(TRB1->RA_XIDCONT) }) 
	oReport:Section(1):Cell("LOCALCON"):SetBlock({|| ALLTRIM(TRB1->RA_XIDLOCT) }) 
	oReport:Section(1):Cell("IDFOLHA"):SetBlock({|| ALLTRIM(TRB1->ZCV_IDFOL) }) 
	oReport:Section(1):Cell("BANCO"):SetBlock({|| SUBSTR(ALLTRIM(TRB1->RA_BCDEPSA),1,3)}) 
	oReport:Section(1):Cell("CONTA"):SetBlock({|| ALLTRIM(TRB1->RA_CTDEPSA) }) 
	oReport:Section(1):Cell("DIGITO"):SetBlock({|| ALLTRIM(TRB1->RA_XDIGAG) }) 
	If Empty(TRB1->ZCV_NUMTIT)
		oReport:Section(1):Cell("CODINCON"):SetBlock({|| ALLTRIM(TRB1->RA_XOCOREN)})
	Else
		oReport:Section(1):Cell("CODINCON"):SetBlock({|| ALLTRIM(TRB1->ZCV_OCORRE)})  
	EndIf
	oReport:Section(1):Cell("DESCINCON"):SetBlock({|| DescOcor(TRB1->EB_DESCRI) })
	
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
@author andre.brito
@since 16/10/2020
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function DescOcor(cDescricao)

Local aArea     := GetArea()
Local aAreaSEB  := SEB->(GetArea())


If Empty(cDescricao)
	cDescricao := "Ocorrência não encontrada ou banco inexistente"
Else
	cDescricao := Alltrim(cDescricao)
EndIf

RestArea(aArea)

RETURN(cDescricao)

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

aAdd(aRegs,{cPerg,"01","ID Folha:      ","","","mv_ch1" ,"C",TamSX3("ZC2_IDFOLH")[1],0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"02","Contrato:      ","","","mv_ch2" ,"C",TamSX3("ZC0_CODIGO")[1],0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","","ZC0","","","",""})
aAdd(aRegs,{cPerg,"03","Local Contr:   ","","","mv_ch3" ,"C",TamSX3("ZC1_LOCCTR")[1],0,0,"G","","MV_PAR03","","","","","","","","","","","","","","","","","","","","","","","","","ZC14","","","",""})
aAdd(aRegs,{cPerg,"04","Banco:   "      ,"","","mv_ch4" ,"C",TamSX3("A6_COD")[1],0,0,"G","","MV_PAR04","","","","","","","","","","","","","","","","","","","","","","","","","SZ1","","","",""})
aAdd(aRegs,{cPerg,"05","Ocorrencia:   " ,"","","mv_ch5" ,"C",TamSX3("EB_REFBAN")[1],0,0,"G","","MV_PAR05","","","","","","","","","","","","","","","","","","","","","","","","","SEB1","","","",""})

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
