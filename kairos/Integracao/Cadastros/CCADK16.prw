#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCADK16
Monitor de fila DW3
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CCADK16()    
Local oBrowse := FwMBrowse():New()

oBrowse:SetAlias("ZCS")
oBrowse:SetDescription("Monitor de fila DW3") 
oBrowse:AddLegend("ZCS_STATUS=='0'", "BR_AMARELO"   , "Pendente")
oBrowse:AddLegend("ZCS_STATUS=='1'", "BR_VERMELHO"  , "Erro")
oBrowse:AddLegend("ZCS_STATUS=='2'", "BR_VERDE"     , "Processado")
oBrowse:DisableDetails() 

// Ativa��o da Classe
oBrowse:Activate()						

RETURN
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Rotina de defini��o do menu
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar"   ACTION "VIEWDEF.CCADK16" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Receber Fila" ACTION "U_CJOBK08"       OPERATION 3 ACCESS 0	
ADD OPTION aRotina TITLE "Enviar Fila"  ACTION "U_CJOBK10"       OPERATION 4 ACCESS 0	
ADD OPTION aRotina TITLE "Legenda"      ACTION "U_CCK16LEG()"    OPERATION 6 ACCESS 0

Return(aRotina)
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Rotina de defini��o do MODEL
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function ModelDef()
Local oStruZCS 	:= FWFormStruct(1, "ZCS")  
Local oModel   	:= MPFormModel():New( 'CCK16MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

oModel:AddFields("ZCSMASTER", /*cOwner*/, oStruZCS)
oModel:SetPrimaryKey({"ZCS_FILIAL","ZCS_IDLOG"})
oModel:SetDescription("Monitor de fila DW3")

Return oModel
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Rotina de defini��o do VIEW
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function ViewDef()
Local oView    	:= FWFormView():New()
Local oStruZCS 	:= FWFormStruct( 2, "ZCS")  
Local oModel   	:= FWLoadModel("CCADK16")           	

oView:SetModel(oModel)
oView:AddField("VIEW", oStruZCS, "ZCSMASTER")
oView:CreateHorizontalBox("TELA", 100)
oView:SetOwnerView("VIEW", "TELA")

Return oView
/*/{Protheus.doc} CCK16LEG
Legenda do monitor de fila Kairos
@author danilo.grodzicki
@since 07/07/2020
@version 12.1.25
@type user function
/*/
User Function CCK16LEG()

BrwLegenda("Monitor de fila DW3","Legenda", { {"BR_VERMELHO", OemToAnsi("Erro"     )},;
									  		  {"BR_VERDE"   , OemToAnsi("Sucesso"  )},;
									  		  {"BR_AMARELO" , OemToAnsi("Processado" )}})

Return Nil
