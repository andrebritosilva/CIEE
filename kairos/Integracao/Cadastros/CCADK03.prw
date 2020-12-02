#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCADK03
Manutenção de Configurações de cobrança
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CCADK03()    
Local oBrowse := FwMBrowse():New()

oBrowse:SetAlias("ZC3")
oBrowse:SetDescription("Configurações de cobrança") 
oBrowse:DisableDetails() 

// Ativação da Classe
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

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.CCADK03" OPERATION 2 ACCESS 0 		

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

Local oModel   	 := MPFormModel():New( 'CCK03MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )
Local oStruZC3 	 := FWFormStruct(1, "ZC3")  
Local oStruZCI   := FWFormStruct(1, "ZCI")

oModel:AddFields("ZC3MASTER", /*cOwner*/, oStruZC3)
oModel:AddGrid("ZCIDETAIL", "ZC3MASTER", oStruZCI)

oModel:SetRelation("ZCIDETAIL",{{"ZCI_FILIAL", 'xFilial( "ZCI" )'},{"ZCI_IDCOBR", "ZC3_IDCOBR"}},ZCI->(IndexKey( 1 )))

oModel:SetPrimaryKey({"ZC3_FILIAL","ZC3_IDCOBR"})

oModel:SetDescription("Configurações de cobrança")

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

Local aCposZCI	:= {"ZCI_IDCONT", "ZCI_LOCCTR"} 
Local oView    	:= FWFormView():New()
Local oStruZC3 	:= FWFormStruct( 2, "ZC3")  
Local oStruZCI 	:= FWFormStruct( 2, "ZCI", {|cCampo|  AScan(aCposZCI , AllTrim(cCampo)) > 0})  
Local oModel   	:= FWLoadModel("CCADK03")           	

oView:SetModel(oModel)
oView:AddField("VIEW_CAB", oStruZC3, "ZC3MASTER")
oView:AddGrid("VIEW_ZCI", oStruZCI, "ZCIDETAIL")

oView:CreateHorizontalBox("SUPERIOR", 60)
oView:CreateHorizontalBox("INFERIOR", 40)

oView:SetOwnerView("VIEW_CAB", "SUPERIOR")
oView:SetOwnerView("VIEW_ZCI", "INFERIOR")

oView:EnableTitleView('VIEW_ZCI','Locais de contrato vinculados' )

Return oView