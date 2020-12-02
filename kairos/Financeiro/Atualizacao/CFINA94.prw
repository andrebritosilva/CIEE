#INCLUDE "TOTVS.CH"           
#Include "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"

/*/{Protheus.doc} User Function CFINA94
Inconsistencias CNAB
@type  Function
@author user
@since 12/05/2020
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function CFINA94()

local cPerg  := PadR("CFINA94", Len(SX1->X1_GRUPO)) 
local cPerAno := "2019/2020/2021/2022/2023/2024/2025/2026/2027/2028/2029/2030/2031/2032/2033/2034/2035/2036/2037/2038/2039/2040"
local cPerMes := "01/02/03/04/05/06/07/08/09/10/11/12"
local aCombo	:= {"Pagamento", "Beneficiario"}
local aParamBox := {}
Private nTipPro := 0 

//ValidPerg(cPerg)

//if pergunte(cPerg,.T.) 

aAdd(aParamBox,{3,"Informe o tipo para liberação","Pagamento",aCombo,90,"",.F.})
aAdd(aParamBox,{1,"Data de pagamento"  ,Ctod(Space(8)),"","","","",50,.F.})

if ParamBox(aParamBox,"Parâmetros...")

	if empty(MV_PAR02)
		alert("Favor preencher a data para processamento")
	else
		TelaIncons()
	endif

endif

return

/*/{Protheus.doc} Static Function TelaIncons
Monta grid com os registros inconsistentes
@type  Function
@author user
@since 12/05/2020
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/

Static Function TelaIncons()

local aArea 	  := GetArea()
local cAliasSRA   := GetNextAlias()
local cQry 		  := ""
Local oWBrowse1   := nil
Local aWBrowse1   := {}
//Local oCheckBo1   := nil
//Local lCheckBo1   := .F.
local _oOk 	   	  := LoadBitmap( GetResources(), "LBOK")
local _oNo 		  := LoadBitmap( GetResources(), "LBNO") 
local oDlg        := nil
local oCancelar   := nil
local oGerarOP    := nil
//local cAnoMes     := alltrim(str(year(MV_PAR02)))+alltrim(strZero(month(MV_PAR02),2))
Local nCont       := 0
Local _aMatSel  := {}

Private dDtRefOP  := MV_PAR02//CTOD("01/"+alltrim(strZero(month(MV_PAR02),2))+"/"+alltrim(str(year(MV_PAR02))))
Private _cMatSel  := ""
Private _cTpCNAB  := ""

if MV_PAR01 == 1

	//Busca movimentos com ocorrencia de rejeição CNAB para pagamento
	cQry := " SELECT "
	cQry += " RD_FILIAL FILIAL, "
	cQry += " RD_MAT MAT, "
	cQry += " RA_NOME, "
	cQry += " RA_CIC, "
	cQry += " RD_PD, "
	cQry += " RD_VALOR, "
	cQry += " RA_BCDEPSA, "
	cQry += " RA_XDIGAG, "
	cQry += " RA_CTDEPSA, "
	cQry += " RA_XDIGCON, "
	cQry += " RA_XORDPGT, "
	cQry += " RA_XDEATIV, "
	cQry += " RD_PERIODO, "
	cQry += " RD_XOCORRE XOCORRE, "
	cQry += " SRD.R_E_C_N_O_ RECNO"
	cQry += " FROM "+RetSqlName("SRD")+" SRD  "
	cQry += " INNER JOIN  "+RetSqlName("SRA")+" SRA ON " 
	cQry += "                   RD_FILIAL=RA_FILIAL AND "
	cQry += "					RD_MAT=RA_MAT AND "
	cQry += "					SRA.D_E_L_E_T_=''  "
	cQry += " INNER JOIN  "+RetSqlName("ZCV")+" ZCV ON " 
	cQry += "                   ZCV_FILIAL=RD_FILIAL AND "
	cQry += "					ZCV_IDFOL=RD_XIDFOL AND "	
	cQry += "					ZCV_MAT=RD_MAT AND "
	cQry += "					ZCV_STATUS='4' AND "
	cQry += "					ZCV.D_E_L_E_T_=''  "	
	cQry += " WHERE  "
	cQry += " SRD.D_E_L_E_T_=''  "
	cQry += " AND RD_PD='J99' "
	//cQry += " AND RD_XNUMTIT='' "
	//cQry += " AND RD_PERIODO='"+cAnoMes+"'  "
	cQry += " AND RD_DATPGT='"+dtos(MV_PAR02)+"'  "
	cQry += " AND RA_XSTATOC = '2' "
	//cQry += " AND (RD_XPROCBX='4' OR RA_XATIVO='N')"

else

	//Busca movimentos com ocorrencia de rejeição CNAB para beneficiario
	cQry := " SELECT "
	cQry += " RQ_FILIAL FILIAL, "
	cQry += " RQ_MAT MAT, "
	cQry += " RA_NOME, "
	cQry += " RA_CIC, "
	cQry += " RD_PD, "
	cQry += " RD_VALOR, "
	cQry += " RA_BCDEPSA, "
	cQry += " RA_XDIGAG, "
	cQry += " RA_CTDEPSA, "
	cQry += " RA_XDIGCON, "
	cQry += " RA_XORDPGT, "
	cQry += " RA_XDEATIV, "
	cQry += " RD_PERIODO, "
	cQry += " RQ_XOCOREN XOCORRE, "
	cQry += " SRQ.R_E_C_N_O_ RECNO"
	cQry += " FROM "+RetSqlName("SRQ")+" SRQ  "
	cQry += " INNER JOIN  "+RetSqlName("SRA")+" SRA ON " 
	cQry += "                   RQ_FILIAL=RA_FILIAL AND "
	cQry += "					RQ_MAT=RA_MAT AND "
	cQry += "					SRA.D_E_L_E_T_=''  "
	cQry += " INNER JOIN "+RetSqlName("SRD")+" SRD ON " 
	cQry += "                   RD_FILIAL=RQ_FILIAL AND "
	cQry += "					RQ_MAT=RD_MAT AND "
	cQry += "					RQ_VERBFOL=RD_PD AND "
	cQry += "					SRD.D_E_L_E_T_=''  "
	cQry += " WHERE  "
	cQry += " SRD.D_E_L_E_T_=''  "
	//cQry += " AND RD_PERIODO='"+cAnoMes+"'  "
	cQry += " AND RD_DATPGT='"+dtos(MV_PAR02)+"'  "
	cQry += " AND RQ_XSTATOC = '2' "
	//cQry += " AND RA_XATIVO='N'"

endif

//cQry += " AND (NOT RD_XOCORRE LIKE '%00%') " // Crédito ou Débito Efetivado 
//cQry += " AND (NOT RD_XOCORRE LIKE '%03%') " // Débito Autorizado pela Agência Efetivado 

cQry := ChangeQuery(cQry)

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasSRA,.T.,.T.)

While (cAliasSRA)->(!EOF()) 

	Aadd(aWBrowse1,{.F.,;
					ALLTRIM((cAliasSRA)->FILIAL),;
					ALLTRIM((cAliasSRA)->MAT),;
					ALLTRIM((cAliasSRA)->RA_NOME),;
					(cAliasSRA)->RA_CIC,;
					(cAliasSRA)->RD_PD,;
					(cAliasSRA)->RD_VALOR,;
					(cAliasSRA)->RD_PERIODO,;
					ALLTRIM((cAliasSRA)->RA_BCDEPSA),;
					ALLTRIM((cAliasSRA)->RA_XDIGAG),;
					ALLTRIM((cAliasSRA)->RA_CTDEPSA),;
					ALLTRIM((cAliasSRA)->RA_XDIGCON),;
					(cAliasSRA)->RA_XORDPGT,;
					ALLTRIM((cAliasSRA)->XOCORRE),;
					DescOcor(SUBSTR(ALLTRIM((cAliasSRA)->RA_BCDEPSA),1,3),(cAliasSRA)->XOCORRE,(cAliasSRA)->RA_XDEATIV),;
					(cAliasSRA)->RECNO})

	(cAliasSRA)->(DbSKIP())
END

(cAliasSRA)->(DbCloseArea())

if len(aWBrowse1) > 0

	DEFINE MSDIALOG oDlg TITLE "Movimentos Folha com Inconsistências de envio CNAB" FROM 000, 000  TO 500, 1000 COLORS 0, 16777215 PIXEL
	
		//@  005, 006 LISTBOX oWBrowse1 VAR cVarQ Fields HEADER " ","Filial","Matr","Nome","CPF","PD","Valor","Período","Ocorr","Descrição","Recno" SIZE 487, 219 ON DBLCLICK (aWBrowse1:=CA710Troca(oWBrowse1:nAt,aWBrowse1),oWBrowse1:Refresh()) ON RIGHT CLICK ListBoxAll(nRow,nCol,@oWBrowse1,_oOk,,@aWBrowse1) NOSCROLL OF oDlg PIXEL
		@  005, 006 LISTBOX oWBrowse1 VAR cVarQ Fields HEADER " ","Filial","Matr","Nome","CPF","PD","Valor","Período","BCOAG","DigA","Conta","DigC","OrdPg?","Ocorr","Descrição","Recno" SIZE 487, 219 ON DBLCLICK (VldDblClic(aWBrowse1,oWBrowse1)) ON RIGHT CLICK ListBoxAll(nRow,nCol,@oWBrowse1,_oOk,,@aWBrowse1) NOSCROLL OF oDlg PIXEL
		//@  235, 006 CHECKBOX oCheckBo1 VAR lCheckBo1 PROMPT "Marca/desmarca todos" SIZE 100, 008 OF oDlg PIXEL ON CLICK (AEval(aWBrowse1, {|z| z[1] := lCheckBo1}), oWBrowse1:Refresh())
	
		oWBrowse1:SetArray(aWBrowse1)
		oWBrowse1:bLine := { || {If(aWBrowse1[oWBrowse1:nAt,1],_oOk,_oNo),aWBrowse1[oWBrowse1:nAt,2],aWBrowse1[oWBrowse1:nAt,3],aWBrowse1[oWBrowse1:nAt,4],aWBrowse1[oWBrowse1:nAt,5],aWBrowse1[oWBrowse1:nAt,6],aWBrowse1[oWBrowse1:nAt,7],aWBrowse1[oWBrowse1:nAt,8],aWBrowse1[oWBrowse1:nAt,9],aWBrowse1[oWBrowse1:nAt,10],aWBrowse1[oWBrowse1:nAt,11],aWBrowse1[oWBrowse1:nAt,12],aWBrowse1[oWBrowse1:nAt,13],aWBrowse1[oWBrowse1:nAt,14],aWBrowse1[oWBrowse1:nAt,15]}}
		
		@ 228, 434 BUTTON oGerarOP PROMPT "&Ordem Pagto" SIZE 058, 017 OF oDlg ACTION (_cTpCNAB  := "OP",oDLg:End()) PIXEL
		@ 228, 370 BUTTON oCancelar PROMPT "&CNAB" SIZE 058, 017 OF oDlg ACTION (_cTpCNAB  := "CN",oDLg:End())  PIXEL
		@ 228, 306 BUTTON oCancelar PROMPT "&Cancelar" SIZE 058, 017 OF oDlg ACTION (oDLg:End())  PIXEL
	   
	ACTIVATE MSDIALOG oDlg CENTERED
	
else

	alert("Não exitem movimentos para o período informado")
	
endif

if !Empty(_cTpCNAB)
	
	for nCont=1 to len(aWBrowse1)

		if aWBrowse1[nCont][1]
		
			AADD(_aMatSel,alltrim(aWBrowse1[nCont][2])+alltrim(aWBrowse1[nCont][3]))
		
			//Flega registro na SCR indicando que foi selecionado
			SRD->(DbGoto(aWBrowse1[nCont][16]))
			RecLock("SRD",.F.)
				if _cTpCNAB == "CN" 
					SRD->RD_XCNABIN := "X" //Gerar CNAB inconsistente
				else
					SRD->RD_XCNABOP := "X" //Gerar CNAB Ordem Pagto
				endif
			SRD->(MsUnLock())

		endif

	NEXT

	if len(_aMatSel) > 0
		_cMatSel := MontaStr(_aMatSel)
		U_CJOBK03()
	else
		alert("Nenhum registro selecionado")
	endif

endif

RestArea(aArea)

return

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

Local _sAlias := Alias()
//Local aPerguntas := {}
Local aRegs := {}
Local i,j

dbSelectArea("SX1")
dbSetOrder(1)

cPerg := PADR(cPerg,10)

//aAdd(aRegs,{cPerg,"01","Data Referência:  ","","","mv_ch1" ,"D",08,0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"01","Ano Ref:  ","","","mv_ch1" ,"C",04,0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"02","Mês Ref:  ","","","mv_ch2" ,"c",02,0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})


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

dbSelectArea(_sAlias)

Return()

/*/{Protheus.doc} ValidPerg
//TODO Descrição Transforma array em string 
@author marcelo.moraes
@since 05/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function MontaStr(_aMatSel)

local cRet  := ""
local nCont := 0

for nCont=1 to len(_aMatSel)
	cRet += "'"+ alltrim(_aMatSel[nCont])+"',"  
end

cRet := SubStr(cRet,1,len(cRet)-1)

return(cRet)

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
				cRet += aOcorr[nCont]+"-"+"Código de ocorrência não cadastrado/"
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

/*/{Protheus.doc} VldDblClic
//TODO Valida Clique Duplo
@author marcelo.moraes
@since 05/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function VldDblClic(aWBrowse1,oWBrowse1)

local lSeleciona := .T.
local cBcoAg     := aWBrowse1[oWBrowse1:nAt][9]
local cDigAg     := aWBrowse1[oWBrowse1:nAt][10]
local cCtaDep    := aWBrowse1[oWBrowse1:nAt][11]
local cDigCon    := aWBrowse1[oWBrowse1:nAt][12]
local cOrdPgto   := aWBrowse1[oWBrowse1:nAt][13]

if aWBrowse1[oWBrowse1:nAt][1]==.F.

	if cOrdPgto<>'S'
		if Empty(cBcoAg) .or. Empty(cDigAg) .or. Empty(cCtaDep) .or. Empty(cDigCon) 
			alert("Dados Bancários Imcompletos!!!, verifique os campos: BCOAG, DigA, Conta, DigC ou OrdPg ")
			lSeleciona := .F.
		endif
	endif

endif

if lSeleciona
	aWBrowse1:=CA710Troca(oWBrowse1:nAt,aWBrowse1)
	oWBrowse1:Refresh()
endif

return
