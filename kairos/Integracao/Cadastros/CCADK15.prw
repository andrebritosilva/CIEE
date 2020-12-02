#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCADK15
Monitor de fila Kairos
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CCADK15()    
Local oBrowse := FwMBrowse():New()

oBrowse:SetAlias("ZCQ")
oBrowse:SetDescription("Monitor de fila Kairós") 
oBrowse:AddLegend("ZCQ_STATUS=='0'", "BR_AMARELO"   , "Pendente")
oBrowse:AddLegend("ZCQ_STATUS=='1'", "BR_VERMELHO"  , "Erro")
oBrowse:AddLegend("ZCQ_STATUS=='2'", "BR_VERDE"     , "Processado")
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

ADD OPTION aRotina TITLE "Visualizar"   ACTION "VIEWDEF.CCADK15" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Receber Fila" ACTION "U_CJOBK07"       OPERATION 3 ACCESS 0	
ADD OPTION aRotina TITLE "Enviar Fila"  ACTION "U_CJOBK09"       OPERATION 4 ACCESS 0	
ADD OPTION aRotina TITLE "Legenda"      ACTION "U_CCK15LEG()"    OPERATION 6 ACCESS 0

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
Local oStruZCQ 	:= FWFormStruct(1, "ZCQ")  
Local oModel   	:= MPFormModel():New( 'CCK15MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

oModel:AddFields("ZCQMASTER", /*cOwner*/, oStruZCQ)
oModel:SetPrimaryKey({"ZCQ_FILIAL","ZCQ_IDLOG"})
oModel:SetDescription("Monitor de fila Kairós")

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
Local oView    	:= FWFormView():New()
Local oStruZCQ 	:= FWFormStruct( 2, "ZCQ")  
Local oModel   	:= FWLoadModel("CCADK15")           	

oView:SetModel(oModel)
oView:AddField("VIEW", oStruZCQ, "ZCQMASTER")
oView:CreateHorizontalBox("TELA", 100)
oView:SetOwnerView("VIEW", "TELA")

Return oView

/*/{Protheus.doc} CCK15LEG
Legenda do monitor de fila Kairos
@author danilo.grodzicki
@since 07/07/2020
@version 12.1.25
@type user function
/*/
User Function CCK15LEG()

BrwLegenda("Monitor de fila Kairós","Legenda", { {"BR_VERMELHO", OemToAnsi("Erro"     )},;
									  		     {"BR_VERDE"   , OemToAnsi("Sucesso"  )},;
									  		     {"BR_AMARELO" , OemToAnsi("Processado" )}})

Return Nil
