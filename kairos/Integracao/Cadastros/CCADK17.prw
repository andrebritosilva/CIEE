#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCADK17
Parâmetros do Token Kairós
@author  	danilo.grodzicki
@since     	14/08/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CCADK17()    

Local oBrowse := FwMBrowse():New()

oBrowse:SetAlias("ZCT")
oBrowse:SetDescription("Parâmetros do Token Kairós")
oBrowse:Activate()

RETURN

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Rotina de definição do menu
@author  	danilo.grodzicki
@since     	14/08/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function MenuDef()

Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.CCADK17" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.CCADK17" OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Alterar"    ACTION "VIEWDEF.CCADK17" OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE "Excluir"    ACTION "VIEWDEF.CCADK17" OPERATION 5 ACCESS 0 		

Return(aRotina)

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Rotina de definição do MODEL
@author  	danilo.grodzicki
@since     	14/08/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function ModelDef()

Local oStruZCT := FWFormStruct(1,"ZCT")
Local oModel   := MPFormModel():New( 'CCK17MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

oModel:AddFields("ZCTMASTER", /*cOwner*/, oStruZCT)
oModel:SetPrimaryKey({"ZCT_FILIAL","ZCT_URLCAL"})                                                                                                     
oModel:SetDescription("Parâmetros do Token Kairós")

Return oModel

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Rotina de definição do VIEW
@author  	danilo.grodzicki
@since     	14/08/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function ViewDef()

Local oView    := FWFormView():New()
Local oStruZCT := FWFormStruct( 2, "ZCT")
Local oModel   := FWLoadModel("CCADK17")

oView:SetModel(oModel)
oView:AddField("VIEW", oStruZCT, "ZCTMASTER")

oView:CreateHorizontalBox("TELA", 100)
oView:SetOwnerView("VIEW", "TELA")

oView:EnableTitleView('VIEW','Parâmetros do Token Kairós' )

Return oView