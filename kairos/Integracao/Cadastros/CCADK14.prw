#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCADK14
Parâmetros de Filas
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CCADK14()    
Local oBrowse := FwMBrowse():New()

oBrowse:SetAlias("ZCP")
oBrowse:SetDescription("Parâmetros de Filas")
oBrowse:AddLegend("ZCP_STATUS=='1'", "BR_VERDE"     , "Ativa")
oBrowse:AddLegend("ZCP_STATUS=='2'", "BR_VERMELHO"  , "Inativa")
oBrowse:Activate()

RETURN
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Rotina de definição do menu
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.CCADK14" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Incluir" ACTION "VIEWDEF.CCADK14" OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Alterar" ACTION "VIEWDEF.CCADK14" OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE "Excluir" ACTION "VIEWDEF.CCADK14" OPERATION 5 ACCESS 0 		

Return(aRotina)
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Rotina de definição do MODEL
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function ModelDef()
Local oStruZCP := FWFormStruct(1, "ZCP")
Local oModel   := MPFormModel():New( 'CCK14MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

oModel:AddFields("ZCPMASTER", /*cOwner*/, oStruZCP)
oModel:SetPrimaryKey({"ZCP_FILIAL","ZCP_RDR","ZCP_TIPO","ZCP_NUM","ZCP_PREFIX","ZCP_PARCEL"})                                                                                                     
oModel:SetDescription("Fechamento de caixa")

Return oModel
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Rotina de definição do VIEW
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function ViewDef()
Local oView    := FWFormView():New()
Local oStruZCP := FWFormStruct( 2, "ZCP")
Local oModel   := FWLoadModel("CCADK14")

oView:SetModel(oModel)
oView:AddField("VIEW", oStruZCP, "ZCPMASTER")

oView:CreateHorizontalBox("TELA", 100)
oView:SetOwnerView("VIEW", "TELA")

oView:EnableTitleView('VIEW','Parâmetros de Filas' )

Return oView