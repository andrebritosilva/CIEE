#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCADK02
Manutenção de configuração de folha
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CCADK02()    
Local oBrowse := FwMBrowse():New()

oBrowse:SetAlias("ZC2")
oBrowse:SetDescription("Configuração de folha") 
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

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.CCADK02" OPERATION 2 ACCESS 0 		

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

Local oStruZC2 	:= FWFormStruct(1, "ZC2")  
Local oStruZCB  := FWFormStruct(1, "ZCB")
Local oModel   	:= MPFormModel():New( 'CCK02MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

oModel:AddFields("ZC2MASTER", /*cOwner*/, oStruZC2)
oModel:AddGrid("ZCBDETAIL", "ZC2MASTER", oStruZCB)

oModel:SetRelation("ZCBDETAIL",{{"ZCB_FILIAL", 'xFilial( "ZCB" )'},{"ZCB_IDFOLH", "ZC2_IDFOLH"}},ZCB->(IndexKey( 1 )))

oModel:SetPrimaryKey({"ZC2_FILIAL","ZC2_IDFOLH"})

oModel:SetDescription("Configuração de folha")

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

Local aCposZCB	:= {"ZCB_IDCNT", "ZCB_IDLOC"} 
Local oView    	:= FWFormView():New()
Local oStruZC2 	:= FWFormStruct( 2, "ZC2")  
Local oStruZCB 	:= FWFormStruct( 2, "ZCB", {|cCampo|  AScan(aCposZCB , AllTrim(cCampo)) > 0})  
Local oModel   	:= FWLoadModel("CCADK02")      
    	
oView:SetModel(oModel)
oView:AddField("VIEW_CAB", oStruZC2, "ZC2MASTER")
oView:AddGrid("VIEW_ZCB", oStruZCB, "ZCBDETAIL")

oView:CreateHorizontalBox("SUPERIOR", 30)
oView:CreateHorizontalBox("INFERIOR", 70)

oView:SetOwnerView("VIEW_CAB", "SUPERIOR")
oView:SetOwnerView("VIEW_ZCB", "INFERIOR")

oView:EnableTitleView('VIEW_ZCB','Locais de contrato vinculados' )

Return oView