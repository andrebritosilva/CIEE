#INCLUDE "TOTVS.CH"           
#Include "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"

/*/{Protheus.doc} User Function CFINA98
Consulta IR Bolsa auxílio
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

User Function CFINA98()

local aArea 	:= GetArea()
local cAlias1   := GetNextAlias()
local cQry 		:= ""
Local oWBrowse1 := nil
Local aWBrowse1 := {}
local oDlg      := nil
Local lXpensao	:= .F.	//Verifica se o Titulo é de Pagamento de Pensão
Local cTitulo	:= "Consulta IR Bolsa auxílio"

if AllTrim(SE2->E2_TIPO) <> "PBA"
	alert("Somente títulos do tipo PBA possuem Consulta IR Bolsa auxílio ")
	return
endif

//Busca movimentos da folha

cQry := " SELECT "  
cQry += " RD_XIDFOL, "                                                                                                                                                                                      
cQry += " RD_MAT, " 
cQry += " RD_XIDCNT, "
cQry += " RD_XIDLOC, "
cQry += " RD_PERIODO, "
cQry += " E2_VENCREA, "
cQry += " RD_VALOR, "
cQry += " RC1.R_E_C_N_O_ AS RECRC1 "
cQry += " FROM "+RetSqlName("SE2")+" SE2 "
cQry += " INNER JOIN "+RetSqlName("RC1")+" RC1 ON "
cQry += " 	RC1_FILIAL = E2_FILIAL AND "
cQry += " 	RC1_PREFIX = E2_PREFIXO AND "
cQry += " 	RC1_NUMTIT = E2_NUM AND "
cQry += " 	RC1_PARC = E2_PARCELA AND "
cQry += " 	RC1_TIPO = E2_TIPO AND "
cQry += " 	RC1_FORNEC = E2_FORNECE AND "
cQry += " 	RC1_LOJA = E2_LOJA AND "
cQry += " 	RC1.D_E_L_E_T_='' "
cQry += " INNER JOIN "+RetSqlName("SRD")+" SRD ON "
cQry += " 	RD_FILIAL = '"+xFilial("SRD")+"' AND "
cQry += " 	RD_XNUMTIT = E2_NUM "
cQry += " 	AND (RD_PD = 'J99' OR RD_PD = '530' OR RD_PD = '554')"
cQry += " 	AND SRD.D_E_L_E_T_='' "
cQry += " WHERE "  
cQry += " SE2.D_E_L_E_T_='' AND "
cQry += " E2_NUM='"+ALLTRIM(SE2->E2_NUM)+"'"
cQry += " ORDER BY RD_XIDFOL,RD_MAT "

cQry := ChangeQuery(cQry)

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAlias1,.T.,.T.)

While (cAlias1)->(!EOF()) 

	RC1->(DBGOTO((cAlias1)->RECRC1))
	lXpensao:= U_TITPENSAO()	//Verifica se o Titulo é de Pagamento de Pensão - (Esta função esta em: CJOBK03.PRW)

	Aadd(aWBrowse1,{(cAlias1)->RD_MAT,;
					ALLTRIM(GetAdvFVal("SRA","RA_NOME" ,XFILIAL("SRA") + (cAlias1)->RD_MAT,1)),;
					STOD((cAlias1)->E2_VENCREA),;
					(cAlias1)->RD_XIDFOL,;
					(cAlias1)->RD_PERIODO,;
					(cAlias1)->RD_XIDCNT,;
					(cAlias1)->RD_XIDLOC,;
					TRANSFORM((cAlias1)->RD_VALOR, "@E 999,999.99"),;
					BuscaVerba((cAlias1)->RD_XIDFOL,(cAlias1)->RD_MAT,(cAlias1)->RD_PERIODO,"004",lXpensao),;
					BuscaVerba((cAlias1)->RD_XIDFOL,(cAlias1)->RD_MAT,(cAlias1)->RD_PERIODO,"277",lXpensao),;
					BuscaVerba((cAlias1)->RD_XIDFOL,(cAlias1)->RD_MAT,(cAlias1)->RD_PERIODO,"A05",lXpensao),;
					BuscaVerba((cAlias1)->RD_XIDFOL,(cAlias1)->RD_MAT,(cAlias1)->RD_PERIODO,"509",lXpensao),;
					BuscaVerba((cAlias1)->RD_XIDFOL,(cAlias1)->RD_MAT,(cAlias1)->RD_PERIODO,"554",lXpensao),;
					lXpensao})

	(cAlias1)->(DbSKIP())
END

(cAlias1)->(DbCloseArea())

if len(aWBrowse1) > 0

	DEFINE MSDIALOG oDlg TITLE "Consulta Analítica" FROM 000, 000  TO 540, 1230 COLORS 0, 16777215 PIXEL
	
		@  005, 006 LISTBOX oWBrowse1 VAR cVarQ Fields HEADER "Matr","Nome","Vencto","IDFolh","Compet","Contrato","Local","Liq Receber","Bolsa Aux","Aux Transp","Base IR","Valor IR","Pensão Alim" SIZE 610, 260  OF oDlg PIXEL
		oWBrowse1:SetArray(aWBrowse1)
		oWBrowse1:bLine := { || {aWBrowse1[oWBrowse1:nAt,1],aWBrowse1[oWBrowse1:nAt,2],aWBrowse1[oWBrowse1:nAt,3],aWBrowse1[oWBrowse1:nAt,4],aWBrowse1[oWBrowse1:nAt,5],aWBrowse1[oWBrowse1:nAt,6],aWBrowse1[oWBrowse1:nAt,7],aWBrowse1[oWBrowse1:nAt,8],aWBrowse1[oWBrowse1:nAt,9],aWBrowse1[oWBrowse1:nAt,10],aWBrowse1[oWBrowse1:nAt,11],aWBrowse1[oWBrowse1:nAt,12],aWBrowse1[oWBrowse1:nAt,13]}}
		
	ACTIVATE MSDIALOG oDlg CENTERED
	
else

	alert("Não exitem movimentos de folha para este título")
	
endif

RestArea(aArea)

return

/*/{Protheus.doc} BuscaVerba
//TODO Retorna valor de uma verba dos movimentos da folha
@author marcelo.moraes
@since 05/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function BuscaVerba(cIDFOL,cMatr,cCompet,cVerba,lXpensao)

local nRet   := 0
local cAlias := GetNextAlias()
Local c2Verba:= cVerba

If cVerba ==  '004' .And. lXpensao	//Se codigo da Verba passado for de Bolsa e tipo de Titulo for Pensão, Retorno Valor 0 para coluna B.A.
	Return 0
Endif

//Trata Tipos de Verbas que indicam Pensão
If cVerba == "554"
	c2Verba:= "530"
Endif

BeginSql Alias cAlias

	SELECT                                                                                                                                                               
		SUM(RD_VALOR) AS VALOR
		FROM %TABLE:SRD% SRD //SRD010 SRD
	WHERE  
		SRD.%notDel%  AND
		RD_FILIAL=%xfilial:SRD% AND
		RD_XIDFOL=%Exp:cIDFOL% AND
		RD_MAT=%Exp:cMatr% AND
		RD_PERIODO=%Exp:cCompet% AND
		(RD_PD= %Exp:AVKEY(cVerba,"RD_PD")% OR RD_PD= %Exp:AVKEY(c2Verba,"RD_PD")% )
		//RD_PD=%Exp:cVerba% 
EndSql

IF (cAlias)->(!EOF())
	nRet := (cAlias)->VALOR	
ENDIF
	
(cAlias)->(dbCloseArea())

RETURN(TRANSFORM(nRet, "@E 999,999.99"))
