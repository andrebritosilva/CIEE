#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} CFINA101
Manutenção Cheques Devolvidos
@author  	danilo.grodzicki
@since     	10/11/2020
@version  	P.12.1.17
@return   	Nenhum
/*/
User Function CFINA101()

Local oBrowse := FwMBrowse():New()

oBrowse:SetAlias("SEF")
oBrowse:SetDescription("Manutenção Cheques Devolvidos")
oBrowse:AddLegend("EF_CART <> 'R'"                             , "BR_AZUL"    , "Cheque da Carteira de Pagamentos")
oBrowse:AddLegend("Empty(EF_ALINEA1) .and. Empty(EF_ALINEA2)"  , "BR_VERDE"   , "Cheque não devolvido"            )
oBrowse:AddLegend("!Empty(EF_ALINEA1) .and. Empty(EF_ALINEA2)" , "BR_AMARELO" , "Cheque com uma devolução"        )
oBrowse:AddLegend("!Empty(EF_ALINEA1) .and. !Empty(EF_ALINEA2)", "BR_VERMELHO", "Cheque com duas devoluções"      )
oBrowse:Activate()

Return

/*/{Protheus.doc} MenuDef
Rotina de definição do menu
@author  	danilo.grodzicki
@since     	10/11/2020
@version  	P.12.1.17
@return   	Nenhum
/*/
Static Function MenuDef()

Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.CFINA101" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.CFINA101" OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Alterar"    ACTION "VIEWDEF.CFINA101" OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE "Excluir"    ACTION "VIEWDEF.CFINA101" OPERATION 5 ACCESS 0
ADD OPTION aRotina TITLE "Legenda"    ACTION "U_CF101LEG()"     OPERATION 6 ACCESS 0

Return(aRotina)

/*/{Protheus.doc} ModelDef
Rotina de definição do MODEL
@author  	danilo.grodzicki
@since     	10/11/2020
@version  	P.12.1.17
@return   	Nenhum
/*/
Static Function ModelDef()

Local nPos

Local oStruSEF := FWFormStruct(1, "SEF")
Local oModel   := MPFormModel():New( 'CFI101MO', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

nPos := aScan( ostrusef:afields, { |x| AllTrim(x[3]) == "EF_PREFIXO" } )
if nPos > 0
	oStruSEF:aFields[nPos][07] := {|a,b,c,d| FWInitCpo(a,b,c),lRet:=((U_NExistCh())),FWCloseCpo(a,b,c,lRet),lRet  }
endif

nPos := aScan( ostrusef:afields, { |x| AllTrim(x[3]) == "EF_TITULO" } )
if nPos > 0
	oStruSEF:aFields[nPos][07] := {|a,b,c,d| FWInitCpo(a,b,c),lRet:=((U_NExistCh())),FWCloseCpo(a,b,c,lRet),lRet  }
endif

nPos := aScan( ostrusef:afields, { |x| AllTrim(x[3]) == "EF_PARCELA" } )
if nPos > 0
	oStruSEF:aFields[nPos][07] := {|a,b,c,d| FWInitCpo(a,b,c),lRet:=((U_NExistCh())),FWCloseCpo(a,b,c,lRet),lRet  }
endif

nPos := aScan( ostrusef:afields, { |x| AllTrim(x[3]) == "EF_TIPO" } )
if nPos > 0
	oStruSEF:aFields[nPos][07] := {|a,b,c,d| FWInitCpo(a,b,c),lRet:=((U_NExistCh())),FWCloseCpo(a,b,c,lRet),lRet  }
endif

nPos := aScan( ostrusef:afields, { |x| AllTrim(x[3]) == "EF_NUM" } )
if nPos > 0
	oStruSEF:aFields[nPos][07] := {|a,b,c,d| FWInitCpo(a,b,c),lRet:=((U_NExistCh())),FWCloseCpo(a,b,c,lRet),lRet  }
endif

nPos := aScan( ostrusef:afields, { |x| AllTrim(x[3]) == "EF_BANCO" } )
if nPos > 0
	oStruSEF:aFields[nPos][07] := {|a,b,c,d| FWInitCpo(a,b,c),lRet:=((U_NExistCh())),FWCloseCpo(a,b,c,lRet),lRet  }
	oStruSEF:aFields[nPos][08] := { || .T. }
endif

nPos := aScan( ostrusef:afields, { |x| AllTrim(x[3]) == "EF_AGENCIA" } )
if nPos > 0
	oStruSEF:aFields[nPos][07] := {|a,b,c,d| FWInitCpo(a,b,c),lRet:=((U_NExistCh())),FWCloseCpo(a,b,c,lRet),lRet  }
endif

nPos := aScan( ostrusef:afields, { |x| AllTrim(x[3]) == "EF_CONTA" } )
if nPos > 0
	oStruSEF:aFields[nPos][07] := {|a,b,c,d| FWInitCpo(a,b,c),lRet:=((U_NExistCh())),FWCloseCpo(a,b,c,lRet),lRet  }
	oStruSEF:aFields[nPos][08] := { || .T. }
endif

oStruSEF:RemoveField("EF_BENEF")
oStruSEF:RemoveField("EF_IMPRESS")
oStruSEF:RemoveField("EF_FORNECE")
oStruSEF:RemoveField("EF_LOJA")
oStruSEF:RemoveField("EF_CART")
oStruSEF:RemoveField("EF_DEPOSIT")
oStruSEF:RemoveField("EF_SERIE")
oStruSEF:RemoveField("EF_NUMNOTA")
oStruSEF:RemoveField("EF_PORTADO")
oStruSEF:RemoveField("EF_HISTD")
oStruSEF:RemoveField("EF_GARANT")
oStruSEF:RemoveField("EF_CHDEVOL")
oStruSEF:RemoveField("EF_TERCEIR")
oStruSEF:RemoveField("EF_COMP")
oStruSEF:RemoveField("EF_OK")
oStruSEF:RemoveField("EF_ORIGEM")
oStruSEF:RemoveField("EF_XNUMAP")
oStruSEF:RemoveField("EF_KEY")
oStruSEF:RemoveField("EF_DTCOMP")
oStruSEF:RemoveField("EF_DEBITO")
oStruSEF:RemoveField("EF_CCD")
oStruSEF:RemoveField("EF_ITEMD")
oStruSEF:RemoveField("EF_CLVLDB")
oStruSEF:RemoveField("EF_CREDIT")
oStruSEF:RemoveField("EF_CCC")
oStruSEF:RemoveField("EF_ITEMC")
oStruSEF:RemoveField("EF_USADOBX")
oStruSEF:RemoveField("EF_NATUR")
oStruSEF:RemoveField("EF_CLVLCR")
oStruSEF:RemoveField("EF_FILCHQ")
oStruSEF:RemoveField("EF_TALAO")
oStruSEF:RemoveField("EF_EC05DB")
oStruSEF:RemoveField("EF_EC05CR")
oStruSEF:RemoveField("EF_SDOC")
oStruSEF:RemoveField("EF_IDSEF")
oStruSEF:RemoveField("EF_LIBER")

oModel:AddFields("SEFMASTER", /*cOwner*/, oStruSEF)
oModel:SetPrimaryKey({"EF_FILIAL","EF_BANCO","EF_AGENCIA","EF_CONTA","EF_NUM"})
oModel:SetDescription("Manutenção Cheques Devolvidos")

Return oModel

/*/{Protheus.doc} ViewDef
Rotina de definição do VIEW
@author  	danilo.grodzicki
@since     	10/11/2020
@version  	P.12.1.17
@return   	Nenhum
/*/
Static Function ViewDef()

Local oView    := FWFormView():New()
Local oStruSEF := FWFormStruct( 2, "SEF")
Local oModel   := FWLoadModel("CFINA101")

oView:SetModel(oModel)
oView:AddField("VIEW", oStruSEF, "SEFMASTER")

oStruSEF:RemoveField("EF_BENEF")
oStruSEF:RemoveField("EF_IMPRESS")
oStruSEF:RemoveField("EF_FORNECE")
oStruSEF:RemoveField("EF_LOJA")
oStruSEF:RemoveField("EF_CART")
oStruSEF:RemoveField("EF_DEPOSIT")
oStruSEF:RemoveField("EF_SERIE")
oStruSEF:RemoveField("EF_NUMNOTA")
oStruSEF:RemoveField("EF_PORTADO")
oStruSEF:RemoveField("EF_HISTD")
oStruSEF:RemoveField("EF_GARANT")
oStruSEF:RemoveField("EF_CHDEVOL")
oStruSEF:RemoveField("EF_TERCEIR")
oStruSEF:RemoveField("EF_COMP")
oStruSEF:RemoveField("EF_OK")
oStruSEF:RemoveField("EF_ORIGEM")
oStruSEF:RemoveField("EF_XNUMAP")
oStruSEF:RemoveField("EF_KEY")
oStruSEF:RemoveField("EF_DTCOMP")
oStruSEF:RemoveField("EF_DEBITO")
oStruSEF:RemoveField("EF_CCD")
oStruSEF:RemoveField("EF_ITEMD")
oStruSEF:RemoveField("EF_CLVLDB")
oStruSEF:RemoveField("EF_CREDIT")
oStruSEF:RemoveField("EF_CCC")
oStruSEF:RemoveField("EF_ITEMC")
oStruSEF:RemoveField("EF_USADOBX")
oStruSEF:RemoveField("EF_NATUR")
oStruSEF:RemoveField("EF_CLVLCR")
oStruSEF:RemoveField("EF_FILCHQ")
oStruSEF:RemoveField("EF_TALAO")
oStruSEF:RemoveField("EF_EC05DB")
oStruSEF:RemoveField("EF_EC05CR")
oStruSEF:RemoveField("EF_SDOC")
oStruSEF:RemoveField("EF_IDSEF")
oStruSEF:RemoveField("EF_LIBER")

oView:CreateHorizontalBox("TELA", 100)
oView:SetOwnerView("VIEW", "TELA")

oView:EnableTitleView('VIEW','Manutenção Cheques Devolvidos' )

Return oView

/*/{Protheus.doc} CF101LEG
Legenda Manutenção Cheques Devolvidos
@author danilo.grodzicki
@since 10/11/2020
@version 12.1.25
@type user function
/*/
User Function CF101LEG()

BrwLegenda("Manutenção Cheques Devolvidos","Legenda", { {"BR_AZUL"    , OemToAnsi("Cheque da Carteira de Pagamentos")},;
									  		            {"BR_VERDE"   , OemToAnsi("Cheque não devolvido"            )},;
									  		            {"BR_AMARELO" , OemToAnsi("Cheque com uma devolução"        )},;
									  		            {"BR_VERMELHO", OemToAnsi("Cheque com duas devoluções"      )}})

Return Nil

/*/{Protheus.doc} NExistCh
Verifica se nao existe um cheque para o mesmo titulo com mesmo número de banco+agencia+conta+cheque para evitar
duplicidade no SEF (Utilizada na validacao do campo no SX3)
@author danilo.grodzicki
@since 10/11/2020
@version 12.1.25
@type user function
/*/
User Function NExistCh()

Local lRet  := .T.
Local aArea := GetArea()

lRet := ExistChav("SEF",If(M->EF_TIPO$MVRECANT," ","R")+M->EF_BANCO+M->EF_AGENCIA+M->EF_CONTA+M->EF_NUM+M->EF_PREFIXO+M->EF_TITULO+M->EF_PARCELA+M->EF_TIPO,6)

// Se nao existe o cheque, pesquisa o titulo e o cliente para sugerir os dados
// como codigo do cliente, loja do cliente, emitente e CNPJ para o cheque
If lRet 
	If !Empty(M->EF_TITULO) .And. !Empty(M->EF_TIPO)
		lRet := ExistCpo("SE1",M->EF_PREFIXO+M->EF_TITULO+M->EF_PARCELA+M->EF_TIPO,1)
	Endif
	If lRet 
		If !Empty(M->EF_TITULO) .And. !Empty(M->EF_TIPO)
			DBSelectArea("SE1")
			SE1->(DBSetOrder(1))
			If MsSeek(xFilial("SE1")+M->EF_PREFIXO+M->EF_TITULO+M->EF_PARCELA+M->EF_TIPO)
				DBSelectArea("SA1")
				DBSetOrder(1)
				If MsSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA)
					M->EF_CLIENTE	:= SE1->E1_CLIENTE
					M->EF_LOJACLI	:= SE1->E1_LOJA
					DbSelectArea("SA1")
					If (Empty(M->EF_EMITENTE) .Or. Empty(M->EF_CPFCNPJ))
						If MsSeek(xFilial("SA1")+M->EF_CLIENTE+M->EF_LOJACLI)
							If Empty(M->EF_EMITENTE)
								M->EF_EMITENTE	:= Left(SA1->A1_NOME,40)
							EndIf
							If Empty(M->EF_CPFCNPJ)
								M->EF_CPFCNPJ	:= SA1->A1_CGC
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf	
	EndIf	
EndIf

DBSelectArea(aArea)

Return lRet

/*/{Protheus.doc} CFI101MO
Ponto de entrada
@author danilo.grodzicki
@since 10/11/2020
@version 12.1.25
@type user function
/*/
User Function CFI101MO()

Local oObj
Local cIdPonto
Local cIdModel

Local aParam := PARAMIXB

If aParam <> NIL
	
	oObj     := aParam[1]
	cIdPonto := aParam[2]
	cIdModel := aParam[3]
	
	if AllTrim(cIdPonto) == "MODELCOMMITNTTS"  // Após a gravação total do modelo e fora da transação.
		
		RecLock("SEF",.F.)
			SEF->EF_CART    := "R"
			SEF->EF_ORIGEM  := "CFINA101"
			SEF->EF_USADOBX := "S"
			SEF->EF_VALORBX := SEF->EF_VALOR
			If Empty(SEF->EF_FILORIG)
				SEF->EF_FILORIG := cFilAnt
			endif
			if !Empty(SEF->EF_DTALIN1)
				SEF->EF_DTREPRE := SEF->EF_DTALIN1 + 1
				SEF->EF_CHDEVOL := "S"
			endif
			if !Empty(SEF->EF_DTALIN2)
				SEF->EF_DTREPRE := SEF->EF_DTALIN2 + 1
				SEF->EF_CHDEVOL := "S"
			endif
			if Empty(SEF->EF_DTALIN1) .and. Empty(SEF->EF_DTALIN2)
				SEF->EF_CHDEVOL := " "
			endif
		SEF->(MsUnlock())

	endif
	
endif

Return(.T.)