#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCADK04
Manutenção de Configurações de Faturamento
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CCADK04()    
Local oBrowse := FwMBrowse():New()

oBrowse:SetAlias("ZC4")
oBrowse:SetDescription("Configurações de Faturamento") 
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

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.CCADK04" OPERATION 2 ACCESS 0 		

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
Local oStruZC4 	:= FWFormStruct(1, "ZC4")  
Local oModel   	:= MPFormModel():New( 'CCK04MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

oModel:AddFields("ZC4MASTER", /*cOwner*/, oStruZC4)
oModel:SetPrimaryKey({"ZC4_FILIAL","ZC4_IDFATU"})
oModel:SetDescription("Configurações de Faturamento")

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
Local oStruZC4 	:= FWFormStruct( 2, "ZC4")  
Local oModel   	:= FWLoadModel("CCADK04")           	

oView:SetModel(oModel)
oView:AddField("VIEW_CAB", oStruZC4, "ZC4MASTER")

oView:AddOtherObject('VIEW_ITENS',{|Obj| CCK04FAI(Obj) },{|| },{||})

oView:CreateHorizontalBox("SUPERIOR", 60)
oView:CreateHorizontalBox("INFERIOR", 40)

oView:SetOwnerView("VIEW_CAB", "SUPERIOR")
oView:SetOwnerView("VIEW_ITENS", "INFERIOR")

oView:EnableTitleView('VIEW_ITENS','Faixas' )

Return oView
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK04FAI
Faixas
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
STATIC FUNCTION CCK04FAI(Obj)
Local aHeader := {}
Local aCols	  := {}
Local nCnta,oGet

AADD(aHeader,{"Minimo","MINIMO","",3,0,"",,"N","","V","","",,"V","",,})
AADD(aHeader,{"Maximo","MAXIMO","",3,0,"",,"N","","V","","",,"V","",,})
AADD(aHeader,{"Valor CI","VALORCI","",14,2,"",,"N","","V","","",,"V","",,})

oJson:= JsonObject():new()
oJson:fromJson(ALLTRIM(ZC4->ZC4_FAIXAS))

For nCnta:=1 to len(oJson["FAIXAS"])
	AADD(aCols,{val(oJson["FAIXAS"][nCnta]:GetJsonText("minimo")) ,;
				val(oJson["FAIXAS"][nCnta]:GetJsonText("maximo")) ,;
				val(oJson["FAIXAS"][nCnta]:GetJsonText("valorCI")) ,; 
				.F.})                   														
Next				

oGet:= MsNewGetDados():New(1,1,1,1,0,"AllwaysTrue","AllwaysTrue",,,,999,"AllwaysTrue()",,,Obj,aHeader,aCols)       	
oGet:oBrowse:Align:= CONTROL_ALIGN_ALLCLIENT

RETURN