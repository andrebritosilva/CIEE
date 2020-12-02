#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCADK07
Movimentação financeira
@author  	Totvs
@since     	21/03/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function CCADK07()

Local oBrowse := FwMBrowse():New()

oBrowse:SetAlias("ZC1")
oBrowse:SetDescription("Movimentação financeira")
oBrowse:DisableDetails()
oBrowse:Activate()

RETURN

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Rotina de definio do menu
@author  	Totvs
@since     	21/03/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar"       ACTION "VIEWDEF.CCADK07" OPERATION 2 ACCESS 0

Return(aRotina)

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Rotina de definio do MODEL
@author  	Totvs
@since     	21/03/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function ModelDef()

Local oStruZC1 := FWFormStruct(1, "ZC1")
Local oStruZCF := FWFormStruct(1, "ZCF",{|cCpo| ALLTRIM(cCpo)$"ZCF_RDR/ZCF_FORPGT/ZCF_IDENT/ZCF_DIDENT/ZCF_TIPO/ZCF_NUM/ZCF_PREFIX/ZCF_PARCEL/ZCF_VALOR/ZCF_SALDO/ZCF_BA/ZCF_CI/ZCF_JUROS/ZCF_DESCON/ZCF_DTPGTO/ZCF_CLIENT/ZCF_LOJA/ZCF_NOMCLI/ZCF_EMISSA/ZCF_VENCRE/ZCF_IDFATU/ZCF_CODCTR/ZCF_LOCCTR/ZCF_COMPET/ZCF_IDFOLH/ZCF_UNIDAD/ZCF_RMU/ZCF_TPSERV/ZCF_DESUNI/ZCF_NAGE/ZCF_DESAGE/ZCF_FECHAM/ZCF_RECIBO" })
Local oModel   := MPFormModel():New( 'CCK07MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

oModel:AddFields("ZC1MASTER", /*cOwner*/, oStruZC1)

oModel:AddGrid("ZCFDETAIL", "ZC1MASTER", oStruZCF ,/*bLinePre*/,,,,{|oModel,Y| loadFieldG(oModel,Y)})

oModel:SetPrimaryKey({"ZC1_FILIAL","ZC1_CODIGO","ZC1_LOCCTR"})

//oModel:SetRelation("ZCFDETAIL",{{'ZCF_FILIAL', 'xFilial("ZCF")'},{"ZCF_CODCTR", "ZC1_CODIGO"},{"ZCF_LOCCTR", "ZC1_LOCCTR"}}, ZCF->( IndexKey( 1 ) ) )

oModel:AddCalc('TOTAIS','ZC1MASTER','ZCFDETAIL','ZCF_SALDO','TOT_CRD','FORMULA',,,'Total Crédito:'       ,{|oMld,x,y,z| CCK07SLD(1,oMld,x,y,z) })
oModel:AddCalc('TOTAIS','ZC1MASTER','ZCFDETAIL','ZCF_BA','TOT_BAX','FORMULA',,,'Total BA:'               ,{|oMld,x,y,z| CCK07SLD(2,oMld,x,y,z) })
oModel:AddCalc('TOTAIS','ZC1MASTER','ZCFDETAIL','ZCF_CI','TOT_CIS','FORMULA',,,'Total CI:'               ,{|oMld,x,y,z| CCK07SLD(3,oMld,x,y,z) })
oModel:AddCalc('TOTAIS','ZC1MASTER','ZCFDETAIL','ZCF_SALDO','TOT_IBA','FORMULA',,,'Total BA Irregular:'  ,{|oMld,x,y,z| CCK07SLD(4,oMld,x,y,z) })
oModel:AddCalc('TOTAIS','ZC1MASTER','ZCFDETAIL','ZCF_SALDO','TOT_SLD','FORMULA',,,'Saldo:'               ,{|oMld,x,y,z| CCK07SLD(5,oMld,x,y,z) })

oModel:SetDescription("Movimentação financeira")

Return oModel

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Rotina de definio do VIEW
@author  	Totvs
@since     	21/03/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function ViewDef()

Local oView    := FWFormView():New()
Local oStruZC1 := FWFormStruct( 2, "ZC1")
Local oStruZCF := nil //FWFormStruct( 2, "ZCF")
Local oModel   := FWLoadModel("CCADK07")
Local oStruTOT := FwCalcStruct(oModel:GetModel("TOTAIS"))

oStruZCF := FWFormStruct(2, "ZCF", {|cCpo| ALLTRIM(cCpo)$"ZCF_RDR/ZCF_FORPGT/ZCF_IDENT/ZCF_DIDENT/ZCF_TIPO/ZCF_NUM/ZCF_PREFIX/ZCF_PARCEL/ZCF_VALOR/ZCF_SALDO/ZCF_BA/ZCF_CI/ZCF_JUROS/ZCF_DESCON/ZCF_DTPGTO/ZCF_CLIENT/ZCF_LOJA/ZCF_NOMCLI/ZCF_EMISSA/ZCF_VENCRE/ZCF_IDFATU/ZCF_CODCTR/ZCF_LOCCTR/ZCF_COMPET/ZCF_IDFOLH/ZCF_UNIDAD/ZCF_RMU/ZCF_TPSERV/ZCF_DESUNI/ZCF_NAGE/ZCF_DESAGE/ZCF_FECHAM/ZCF_RECIBO"})

oView:SetModel(oModel)
oView:AddField("VIEW_CAB"   , oStruZC1, "ZC1MASTER")
oView:AddGrid("VIEW_ITENS"  , oStruZCF, "ZCFDETAIL")
oView:AddField("VIEW_TOTAIS", oStruTOT, "TOTAIS"   )

oView:CreateHorizontalBox("SUPERIOR", 20)
oView:CreateHorizontalBox("INFERIOR", 70)
oView:CreateHorizontalBox("RODAPE"  , 10)

oView:SetOwnerView("VIEW_CAB"	, "SUPERIOR")
oView:SetOwnerView("VIEW_ITENS"	, "INFERIOR")
oView:SetOwnerView("VIEW_TOTAIS", "RODAPE"  )

oView:EnableTitleView('VIEW_ITENS','Movimentação financeira' )

Return oView

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK07SLD
Rotina de calculo do saldo
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function CCK07SLD(nId,oModel,nTotAtu,nValor,lSoma)

DO CASE
	//Soma créditos
	CASE nId == 1
		if oModel:GetValue("ZCFDETAIL","ZCF_PREFIX") == "CRD"
			nTotAtu += nValor
		endif
	//Soma BA
	CASE nId == 2
		if oModel:GetValue("ZCFDETAIL","ZCF_PREFIX") == "PBA"
			nTotAtu += nValor
		endif
	//Soma CI
	CASE nId == 3
		if oModel:GetValue("ZCFDETAIL","ZCF_PREFIX") == "RPS"
			nTotAtu += nValor
		endif
	//Soma IBA
	CASE nId == 4
		if oModel:GetValue("ZCFDETAIL","ZCF_PREFIX") == "IBA"
			nTotAtu += nValor
		endif
	//Calcula saldo
	CASE nId == 5
		If oModel:GetValue("ZCFDETAIL","ZCF_PREFIX") == "CRD"
			nTotAtu += oModel:GetValue("ZCFDETAIL","ZCF_SALDO")
		elseif  oModel:GetValue("ZCFDETAIL","ZCF_PREFIX") == "PBA"
			nTotAtu -= oModel:GetValue("ZCFDETAIL","ZCF_BA")
		elseif oModel:GetValue("ZCFDETAIL","ZCF_PREFIX") == "RPS"
			nTotAtu -= oModel:GetValue("ZCFDETAIL","ZCF_CI")
		elseif oModel:GetValue("ZCFDETAIL","ZCF_PREFIX") == "IBA"
			nTotAtu += oModel:GetValue("ZCFDETAIL","ZCF_SALDO")
		endif
ENDCASE

Return nTotAtu

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} loadFieldG
Carrega movimentos financeiros
@author  	Totvs
@since     	16/09/2020
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function loadFieldG(oFieldModel, lCopy)

local aRet       := {}
local _caliasZCF := GetNextAlias()
local _caliasCRD := GetNextAlias()
local _caliasICO := GetNextAlias()
local cRegist    := ""
local _cQuery    := ""

_cQuery += " SELECT " + CposQuery()
_cQuery += " FROM "+RetSqlName("ZCF")+" ZCF "
_cQuery += " WHERE " 
_cQuery += "	ZCF.D_E_L_E_T_='' "
_cQuery += "	AND ZCF_FILIAL='"+xFilial("ZCF")+"'"
_cQuery += "	AND ZCF_CODCTR = '"+ZC1->ZC1_CODIGO+"'"
_cQuery += "	AND ZCF_LOCCTR = '"+ZC1->ZC1_LOCCTR+"'"
_cQuery += "	AND ZCF_FECHAM = '1' "
_cQuery += "	AND ZCF_PREFIX <> 'CRD' "

_cQuery := ChangeQuery(_cQuery)

dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),_caliasZCF,.T.,.T.)

WHILE (_caliasZCF)->(!EOF())

		cRegist += "'"+ALLTRIM((_caliasZCF)->ZCF_REGIST)+"',"

		aAdd(aRet,{0, {(_caliasZCF)->ZCF_RDR,;
						 (_caliasZCF)->ZCF_FORPGT,;
						 (_caliasZCF)->ZCF_IDENT,;
						 (_caliasZCF)->ZCF_DIDENT,;
						 (_caliasZCF)->ZCF_TIPO,;
						 (_caliasZCF)->ZCF_NUM,;
						 (_caliasZCF)->ZCF_PREFIX,;
						 (_caliasZCF)->ZCF_PARCEL,; 
						 (_caliasZCF)->ZCF_VALOR,;
						 (_caliasZCF)->ZCF_SALDO,;
						 (_caliasZCF)->ZCF_BA,; 
						 (_caliasZCF)->ZCF_CI,;
						 (_caliasZCF)->ZCF_JUROS,;
						 (_caliasZCF)->ZCF_DESCON,;
						 STOD((_caliasZCF)->ZCF_DTPGTO),;
						 (_caliasZCF)->ZCF_CLIENT,; 
						 (_caliasZCF)->ZCF_LOJA,;
						 (_caliasZCF)->ZCF_NOMCLI,;
						 STOD((_caliasZCF)->ZCF_EMISSA),;
						 STOD((_caliasZCF)->ZCF_VENCRE),;
						 (_caliasZCF)->ZCF_IDFATU,; 
						 (_caliasZCF)->ZCF_CODCTR,;
						 (_caliasZCF)->ZCF_LOCCTR,;
						 (_caliasZCF)->ZCF_COMPET,;
						 (_caliasZCF)->ZCF_IDFOLH,;
						 (_caliasZCF)->ZCF_UNIDAD,; 
						 (_caliasZCF)->ZCF_RMU,;
						 (_caliasZCF)->ZCF_TPSERV,;
						 (_caliasZCF)->ZCF_DESUNI,;
						 (_caliasZCF)->ZCF_NAGE,;
						 (_caliasZCF)->ZCF_DESAGE,;
						 (_caliasZCF)->ZCF_FECHAM,;
						 (_caliasZCF)->ZCF_RECIBO}})

	(_caliasZCF)->(DBSKIP())
	
END 

(_caliasZCF)->(dbCloseArea())

if !Empty(cRegist)

	cRegist := substr(cRegist,1,len(cRegist)-1)

	_cQuery := ""

	//Busca os movimentos de credito
	_cQuery += " SELECT " + CposQuery()
	_cQuery += " FROM "+RetSqlName("ZCF")+" ZCF "
	_cQuery += " WHERE " 
	_cQuery += "	ZCF.D_E_L_E_T_='' "
	_cQuery += "	AND ZCF_FILIAL='"+xFilial("ZCF")+"'"
	_cQuery += "	AND ZCF_REGIST IN ("+cRegist+")"
	_cQuery += "	AND ZCF_PREFIX = 'CRD' "

	_cQuery := ChangeQuery(_cQuery)

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),_caliasCRD,.T.,.T.)

	WHILE (_caliasCRD)->(!EOF())

		aAdd(aRet,{0, {(_caliasCRD)->ZCF_RDR,;
						 (_caliasCRD)->ZCF_FORPGT,;
						 (_caliasCRD)->ZCF_IDENT,;
						 (_caliasCRD)->ZCF_DIDENT,;
						 (_caliasCRD)->ZCF_TIPO,;
						 (_caliasCRD)->ZCF_NUM,;
						 (_caliasCRD)->ZCF_PREFIX,;
						 (_caliasCRD)->ZCF_PARCEL,; 
						 (_caliasCRD)->ZCF_VALOR,;
						 (_caliasCRD)->ZCF_SALDO,;
						 (_caliasCRD)->ZCF_BA,; 
						 (_caliasCRD)->ZCF_CI,;
						 (_caliasCRD)->ZCF_JUROS,;
						 (_caliasCRD)->ZCF_DESCON,;
						 STOD((_caliasCRD)->ZCF_DTPGTO),;
						 (_caliasCRD)->ZCF_CLIENT,; 
						 (_caliasCRD)->ZCF_LOJA,;
						 (_caliasCRD)->ZCF_NOMCLI,;
						 GetAdvFVal("ZCG","ZCG_EMISSA" ,XFILIAL("ZCG")+(_caliasCRD)->ZCF_REGIST,6),;
						 STOD((_caliasCRD)->ZCF_VENCRE),;
						 (_caliasCRD)->ZCF_IDFATU,; 
						 (_caliasCRD)->ZCF_CODCTR,;
						 (_caliasCRD)->ZCF_LOCCTR,;
						 (_caliasCRD)->ZCF_COMPET,;
						 (_caliasCRD)->ZCF_IDFOLH,;
						 (_caliasCRD)->ZCF_UNIDAD,; 
						 (_caliasCRD)->ZCF_RMU,;
						 (_caliasCRD)->ZCF_TPSERV,;
						 (_caliasCRD)->ZCF_DESUNI,;
						 (_caliasCRD)->ZCF_NAGE,;
						 (_caliasCRD)->ZCF_DESAGE,;
						 (_caliasCRD)->ZCF_FECHAM,;
						 (_caliasCRD)->ZCF_RECIBO}})

		(_caliasCRD)->(DBSKIP())
	
	END 

	(_caliasCRD)->(dbCloseArea())

endif

//Busca as movimentações de Inconsistencia de Bousa Auxilio (pagamentos que estao irregulares)

_cQuery := ""

_cQuery += " SELECT "
_cQuery += " RA_FILIAL, "
_cQuery += " RD_VALOR, "
_cQuery += " RD_DATPGT, "
_cQuery += " RD_DTREF, "
_cQuery += " RD_XIDFOL, "
_cQuery += " RD_PERIODO, "
_cQuery += " RD_XNUMTIT, "
_cQuery += " RD_XIDCNT, "
_cQuery += " RD_XIDLOC "
_cQuery += " FROM "+RetSqlName("SRD")+" RD "
_cQuery += " INNER JOIN "+RetSqlName("SRA")+" RA ON RA.RA_FILIAL = RD.RD_FILIAL AND RA.RA_MAT = RD.RD_MAT AND RA.D_E_L_E_T_ = ' ' " 
_cQuery += " LEFT JOIN "+RetSqlName("SRQ")+" RQ ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' ' " 
_cQuery += " INNER JOIN "+RetSqlName("SEB")+"  EB ON EB.EB_BANCO = SUBSTRING(RA.RA_BCDEPSA,1,3) AND EB.EB_REFBAN = RD.RD_XOCORRE AND EB.D_E_L_E_T_ = ' ' " 
_cQuery += " WHERE " 
_cQuery += " RD.RD_FILIAL = '"+xFilial("SRD")+"' " 
_cQuery += " AND RD.RD_XOCORRE != '' " 
_cQuery += " AND EB.EB_OCORR = '03' " 
_cQuery += " AND RD.RD_XIDCNT = '"+ZC1->ZC1_CODIGO+"' " 
_cQuery += " AND RD.RD_XIDLOC = '"+ZC1->ZC1_LOCCTR+"' " 
_cQuery += " AND RD.D_E_L_E_T_ = ' ' " 

_cQuery := ChangeQuery(_cQuery)

dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),_caliasICO,.T.,.T.)

WHILE (_caliasICO)->(!EOF())

	aAdd(aRet,{0, {"",;
					"",;
					"",;
					"",;
					"IBA",;
					(_caliasICO)->RD_XNUMTIT,;
					"IBA",;
					"",; 
					(_caliasICO)->RD_VALOR,;
					(_caliasICO)->RD_VALOR,;
					0,; 
					0,;
					0,;
					0,;
					STOD((_caliasICO)->RD_DATPGT),;
					"",; 
					"",;
					"",;
					STOD((_caliasICO)->RD_DTREF),;
					CTOD(""),;
					"",; 
					(_caliasICO)->RD_XIDCNT,;
					(_caliasICO)->RD_XIDLOC,;
					(_caliasICO)->RD_PERIODO,;
					(_caliasICO)->RD_XIDFOL,;
					"",; 
					"",;
					"",;
					"",;
					"",;
					"",;
					"",;
					""}})


	(_caliasICO)->(DBSKIP())
END

(_caliasICO)->(dbCloseArea())

Return aRet


//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CposQuery
Campos Query
@author  	Totvs
@since     	16/09/2020
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function CposQuery()

local cRet := ""

cRet += "ZCF_RDR,"
cRet += "ZCF_FORPGT,"
cRet += "ZCF_IDENT,"
cRet += "ZCF_DIDENT,"
cRet += "ZCF_TIPO,"
cRet += "ZCF_NUM,"
cRet += "ZCF_PREFIX,"
cRet += "ZCF_PARCEL,"
cRet += "ZCF_VALOR,"
cRet += "ZCF_SALDO,"
cRet += "ZCF_BA,"
cRet += "ZCF_CI,"
cRet += "ZCF_JUROS,"
cRet += "ZCF_DESCON,"
cRet += "ZCF_DTPGTO,"
cRet += "ZCF_CLIENT,"
cRet += "ZCF_LOJA,"
cRet += "ZCF_NOMCLI,"
cRet += "ZCF_EMISSA,"
cRet += "ZCF_VENCRE,"
cRet += "ZCF_IDFATU,"
cRet += "ZCF_CODCTR,"
cRet += "ZCF_LOCCTR,"
cRet += "ZCF_COMPET,"
cRet += "ZCF_IDFOLH,"
cRet += "ZCF_UNIDAD,"
cRet += "ZCF_RMU,"
cRet += "ZCF_TPSERV,"
cRet += "ZCF_DESUNI,"
cRet += "ZCF_NAGE,"
cRet += "ZCF_DESAGE,"
cRet += "ZCF_FECHAM,"
cRet += "ZCF_RECIBO,"
cRet += "ZCF_REGIST" 

return(cRet)
