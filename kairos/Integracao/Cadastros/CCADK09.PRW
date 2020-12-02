#Include 'Protheus.ch'
#Include 'Topconn.ch'
#INCLUDE "FWMVCDEF.CH"

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCADK09
Creditos Nao Identificados - Fechamento
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CCADK09()
Local oBrowse := FwMBrowse():New()

oBrowse:SetAlias("ZCG")
oBrowse:SetDescription("CNI - Fechamento de Creditos Nao Identificados")

oBrowse:AddLegend("Empty(ZCG_FECHA)", "BR_VERDE", "Não Analisado")
oBrowse:AddLegend("!Empty(ZCG_FECHA)", "BR_VERMELHO", "Analisado")


oBrowse:DisableDetails()
oBrowse:Activate()

Return


//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Rotina de definio do menu
@author  	carlos.henrique
@since     	21/03/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.CCADK09" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Fechamento" ACTION "U_CRELK01" OPERATION 3 ACCESS 0


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
Local oStruZCG := FWFormStruct(1, "ZCG")
Local oModel   := MPFormModel():New( 'CCK06MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

oModel:AddFields("ZCGMASTER", /*cOwner*/, oStruZCG)
oModel:SetPrimaryKey({"ZCG_FILIAL","ZCG_REGIST"})
oModel:SetDescription("Creditos Não Identificados")

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
Local oStruZCG := FWFormStruct( 2, "ZCG")
Local oModel   := FWLoadModel("CCADK06")

oView:SetModel(oModel)
oView:AddField("VIEW_CAB"   , oStruZCG, "ZCGMASTER")

oView:CreateHorizontalBox("PAINEL", 100)

oView:SetOwnerView("VIEW_CAB"	, "PAINEL")

Return oView