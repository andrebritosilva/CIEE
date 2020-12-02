#INCLUDE 'PROTHEUS.CH'
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TOPCONN.CH"

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCADK06
Cadastro de Créditos não Identificados
@author  	carlos.henrique
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
@history    24/07/2020, Mário Augusto Cavenaghi - EthosX: Criação Baixa por Tesouraria
/*/
//---------------------------------------------------------------------------------------
User Function CCADK06()

	Local oBrowse := FwMBrowse():New()

	oBrowse:SetAlias("ZCG")
	oBrowse:SetDescription("CNI - Créditos Não Identificados")
	oBrowse:AddLegend("ZCG_SALDO == ZCG_VALOR", "BR_AMARELO", "Pendente")
	oBrowse:AddLegend("ZCG_SALDO < ZCG_VALOR .AND. ZCG_SALDO > 0", "BR_AZUL", "Baixado Parcialmente")
	oBrowse:AddLegend("ZCG_SALDO==0", "BR_VERMELHO" , "Baixado")
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

	ADD OPTION aRotina TITLE "Visualizar"    ACTION "VIEWDEF.CCADK06" OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE "Incluir"       ACTION "VIEWDEF.CCADK06" OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar"       ACTION "VIEWDEF.CCADK06" OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir"       ACTION "VIEWDEF.CCADK06" OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE "Importar"      ACTION "U_CCK06IMP"      OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Baixar"        ACTION "U_CCK06BXA"      OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Tesouraria"    ACTION "U_CCK06TSR"      OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Validação DW3" ACTION "U_CCK06DW3"      OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Imprimir"      ACTION "U_CCK06REL"      OPERATION 4 ACCESS 0

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
	oModel:SetDescription("Créditos Não Identificados")

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


//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Importacao de Extrato Bancario
@author  	Microsiga
@since     	06/05/07
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function CCK06IMP()

	Local oOk   := LoadBitmap( GetResources(), "LBOK" )
	Local oNo   := LoadBitmap( GetResources(), "LBNO" )

	Private aBanco	:= {}

	aAdd(aBanco,{.F.,"001","Banco do Brasil"	})
	aAdd(aBanco,{.F.,"237","Banco Bradesco"		})
	aAdd(aBanco,{.F.,"341","Banco Itaú"			})
	aAdd(aBanco,{.F.,"356","ABN AMRO Real"		})
	aAdd(aBanco,{.F.,"104","Caixa Economica"	})
	aAdd(aBanco,{.F.,"033","Santander Banespa"	})

	DEFINE MSDIALOG oDlg FROM  31,58 To 300,500 TITLE "Qual Banco Deseja Importar o Extrato?" PIXEL
	@ 05,05 LISTBOX oLbx1 FIELDS HEADER "","Banco","Nome" SIZE 215, 85 OF oDlg PIXEL ON DBLCLICK (U_CCK06M01())

	oLbx1:SetArray(aBanco)
	oLbx1:bLine := { || {Iif(aBanco[oLbx1:nAt,1],oOk,oNo),aBanco[oLbx1:nAt,2],aBanco[oLbx1:nAt,3] } }
	oLbx1:nFreeze  := 1

	DEFINE SBUTTON FROM 94, 150 TYPE 1  ENABLE OF oDlg ACTION Processa({||  U_CCK06EIM() },"Processando Registros...")
	DEFINE SBUTTON FROM 94, 190 TYPE 2  ENABLE OF oDlg ACTION (lRet :=.F.,oDlg:End())

	ACTIVATE MSDIALOG oDlg CENTERED

Return()


//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK06EIM
Importacao de Extrato Bancario 
@author  	Microsiga
@since     	06/05/07
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function CCK06EIM()

	Local _nI:= 0

	Private lInverte := .F.
	Private cMarca
	Private aParambox 	:={}

	aAdd(aParambox,{1,'Data Import',(dDataBase-1),"","","","",0,.T.})

	If !Parambox(aParambox,'Informe a Data para Importação')
		Return
	Endif

	For _nI := 1 To Len(aBanco)
		If aBanco[_nI,1]
			oLbx1:nAt := _nI
		Endif
	Next _nI

	Do Case
	Case aBanco[oLbx1:nAt,2] == "001" .and. aBanco[oLbx1:nAt,1]
		If cEmpant == '03' //RJ
			cDirect    := "\arq_txtrj\tesouraria\Importacao\BancodoBrasil\"
			cDirectImp := "\arq_txtrj\tesouraria\Importacao\BancodoBrasil\Debito\"
		Else
			cDirect    := "\arq_txt\tesouraria\Importacao\BancodoBrasil\"
			cDirectImp := "\arq_txt\tesouraria\Importacao\BancodoBrasil\Debito\"		
		Endif
		aDirect    := Directory(cDirect+"*.RET")

		If Empty(adirect)
			MsgAlert("Não existe nenhum arquivo para ser Importado!!!")
			Return
		Endif

		For _nI := 1 To Len(adirect)
			FT_FUSE(cDirect+adirect[_nI,1])
			FT_FGOTOP()
			cBuffer 	:=	Alltrim(FT_FREADLN())

			If Substr(cBuffer,77,3) <> "001"
				alert("Arquivo não Pertence ao Banco do Brasil!")
				Return
			Endif

			If Len(cBuffer)< 200 .or. Len(cBuffer)> 200
				alert("Formato do arquivo Inválido!")
				Return
			Endif
		/*|-----------------------------------------------|
		  | Pula o primeiro registro                      |
		  | Cabecalho                                     |
		  |-----------------------------------------------|*/
			FT_FSKIP()
			ProcRegua(FT_FLASTREC())
			_lFirst := .T.

			While !FT_FEOF()
				IncProc("Processando Leitura do Arquivo Texto...")
				cBuffer     :=	Alltrim(FT_FREADLN())
				_cID        := Substr(cBuffer,001,01) // 0-Cabecalho; 1-Detalhes; 9-Rodape
				_cTpSaldo   := Substr(cBuffer,042,01) // 0-Saldo Anterior; 2-Saldo Atual
				_cCategoria := Substr(cBuffer,043,01) // Definicao de Credito/ Debito. 1-Debito, 2-Credito. Codigo da Categoria de Lancamento. EX: 201 Deposito
				_cTpBlq     := Substr(cBuffer,046,04) // Utilizado para detectar codigo 0911 para itens Bloqueados
				_cHist      := Substr(cBuffer,050,25) // Historico do lancamento pelo Banco
			/*|--------------------------------------------------------------------|
			  | Pula os registros de Saldo Anterior e Atual (_cTpSaldo)            |
			  |                      Rodape - 9 (_cID)                             |
			  | registros de Debito também não sao importados - 1xx (_cCategoria)  |
			  |--------------------------------------------------------------------|*/
				If _cTpSaldo $ "0|2" .or. _cID == "9" .or. _cCategoria == "1"
					FT_FSKIP()
					Loop
				Endif

				If _cTpBlq == "0911" //Codigo para Lancamentos Bloqueados pelo Banco
					FT_FSKIP()
					Loop
				Endif

				_cAgencia	:=	Substr(cBuffer,018,04)
				_cConta  	:=	Substr(cBuffer,030,12)  
				_cTipo   	:=	Substr(cBuffer,043,03)
				_cDeposit	:=	ALLTRIM(STR(VAL(Substr(cBuffer,136,15)),30))  // CNPJ do Depositante
				_cDocument	:=	Substr(cBuffer,75,06)   // Numero do Documento 
				_cEmissao	:=	Substr(cBuffer,081,06)
				_cData 		:= ctod(SUBSTR(_cEmissao,1,2)+"/"+SUBSTR(_cEmissao,3,2)+"/"+SUBSTR(_cEmissao,5,2))
				_cValor  	:=	Substr(cBuffer,087,18) 
				_dAntServ	:= DATE() - 1

				// 07/03/2013 - Patricia Fontanezi
				If _cTipo == "213" .AND. _cTpBlq == "0870"
					_cTipo	:= "45"
				Endif

			 	//If _cData < DataValida(_dAntServ,.F.)
				If _cData <> mv_par01
					FT_FSKIP()
					Loop
				Endif

			/*|--------------------------------------------------------------------------------|
			  | Pesquisa registros do arquivo TXT na base ZCG com a chave                      |
			  | EMISSAO+DOCUMENTO+VALOR+DEPOSITANTE se achou não importa o registro novamente  |
			  |--------------------------------------------------------------------------------|*/
				cQuery 		:= " SELECT COUNT(*) AS NREG"
				cQuery 		+= " FROM "+RetSQLname('ZCG')+" "
				cQuery 		+= " WHERE D_E_L_E_T_ <> '*' "
				cQuery 		+= " AND ZCG_IMPFLG = 'S' "
				cQuery 		+= " AND ZCG_EMISSA = '"+DTOS(_cData)+"' "
				cQuery 		+= " AND ZCG_NDOC  = '"+_cDocument+"' "
				cQuery 		+= " AND ZCG_DEPOS = '"+Upper(Substr(_cDeposit,1,30))+"' "
				cQuery 		+= " AND ZCG_VALOR  = '"+ALLTRIM(STR((VAL(_cValor)/100),20,2))+"' "
				TcQuery cQuery New Alias "ZCGPESQ"

				If ZCGPESQ->NREG > 0
					FT_FSKIP()
					ZCGPESQ->(DbCloseArea())
					Loop
				Else
					ZCGPESQ->(DbCloseArea())
				Endif

				/*
				//Alterado pelo analista Emerson dia 17/11/11.
				//Acrescentado no campo ZCG_REGIST o comando GETSXENUM("ZCG","ZCG_REGIST") para que o sistema gere automaticamente a numeracao

				cQuery := "SELECT ZCG_REGIST, SUBSTRING(ZCG_REGIST,3,15) AS NREG "
				cQuery += "FROM "+RetSQLname('ZCG')+" "
				cQuery += "ORDER BY ZCG_REGIST DESC "
				TcQuery cQuery New Alias "REGTMP"
				*/

				DbSelectArea("SA6")
				DbSetOrder(5) // FILIAL+CONTA
				If DbSeek(xFilial("SA6")+alltrim(str(val(_cConta),10)),.T.)
					If SA6->A6_COD == "001"
						RecLock("ZCG",.T.)
						ZCG->ZCG_FILIAL	:= xFilial("ZCG")
						ZCG->ZCG_BANCO  := "001"
						ZCG->ZCG_AGENCI := SA6->A6_AGENCIA
						ZCG->ZCG_CONTA  := SA6->A6_NUMCON
						ZCG->ZCG_EMISSA := _cData
						ZCG->ZCG_TIPO   := _cTipo
						ZCG->ZCG_DEPOS  := Upper(_cDeposit)
						ZCG->ZCG_VALOR  := VAL(_cValor)/100
						ZCG->ZCG_NDOC   := _cDocument
						ZCG->ZCG_CCONT  := SA6->A6_CONTABI //Conta Contabil do Banco (Reduzida)
						ZCG->ZCG_REGIST := GETSXENUM("ZCG","ZCG_REGIST") //Right(Str(Year(dDataBase)),2)+strzero((val(REGTMP->NREG)+1),13) //Alterado dia 10/10/07 pelo analista Emerson
						ZCG->ZCG_IMPFLG := "S" //Flag para definir registros Importados
						ZCG->ZCG_HIST   := _cHist
						ZCG->ZCG_SALDO  := ZCG->ZCG_VALOR
						MsUnLock()
						ConfirmSX8()
					Endif
				Endif

				/*
				DbSelectArea("REGTMP")
				DbCloseArea("REGTMP")
				*/

				FT_FSKIP()
			EndDo
			FT_FUSE()
		Next
	Case aBanco[oLbx1:nAt,2] == "237" .and. aBanco[oLbx1:nAt,1]
		If cEmpant == '03' //RJ
			cDirect    := "\arq_txtrj\tesouraria\Importacao\Bradesco\"
			cDirectImp := "\arq_txtrj\tesouraria\Importacao\Bradesco\Backup\"
		Else
			cDirect    := "\arq_txt\tesouraria\Importacao\Bradesco\"
			cDirectImp := "\arq_txt\tesouraria\Importacao\Bradesco\Backup\"		
		Endif
		aDirect    := Directory(cDirect+"*.RET")

		If Empty(adirect)
			MsgAlert("Não existe nenhum arquivo para ser Importado!!!")
			Return
		Endif

		For _nI := 1 To Len(adirect)
			FT_FUSE(cDirect+adirect[_nI,1])
			FT_FGOTOP()
			cBuffer 	:=	Alltrim(FT_FREADLN())

			If Substr(cBuffer,77,3) <> "237"
				alert("Arquivo não Pertence ao Banco Bradesco!")
				Return
			Endif

			If Len(cBuffer)< 200 .or. Len(cBuffer)> 200
				alert("Formato do arquivo Inválido!")
				Return
			Endif
		/*|-----------------------------------------------|
		  | Pula o primeiro registro                      |
		  | Cabecalho                                     |
		  |-----------------------------------------------|*/
			FT_FSKIP()
			ProcRegua(FT_FLASTREC())
			_lFirst := .T.

			While !FT_FEOF()
				IncProc("Processando Leitura do Arquivo Texto...")
				cBuffer 	:=	Alltrim(FT_FREADLN())
				_cID	    := Substr(cBuffer,001,1) // 0-Cabecalho; 1-Detalhes; 9-Rodape
				_cTpSaldo   := Substr(cBuffer,042,1) // 0-Saldo Anterior; 2-Saldo Atual
				_cCategoria := Substr(cBuffer,043,1) // Definicao de Credito/ Debito. 1-Debito, 2-Credito. Codigo da Categoria de Lancamento. EX: 201 Deposito
				_cTipo   	:= Substr(cBuffer,043,3) // Pula Tipo 213 - Transferencia entre CC - Realizado via Movimento Bancario
				_cTpBlq		:= Substr(cBuffer,046,04) // Utilizado para detectar codigo 0911 para itens Bloqueados
				_cHist		:= Substr(cBuffer,050,25) // Historico do lancamento pelo Banco
			/*|--------------------------------------------------------------------|
			  | Pula os registros de Saldo Anterior e Atual (_cTpSaldo)            |
			  |                      Rodape - 9 (_cID)                             |
			  | registros de Debito também não sao importados - 1xx (_cCategoria)  |
			  |--------------------------------------------------------------------|*/
				//If _cTpSaldo $ "0|2" .or. _cID == "9" .or. _cCategoria == "1" .or. _cTipo $ "213|205|206"
				If _cTpSaldo $ "0|2" .or. _cID == "9" .or. _cCategoria == "1" .or. _cTipo $ "213|206" // Alterado para importar os tipos 205 - solicitação do Adilson da Tesouraria
					FT_FSKIP()
					Loop
				Endif

				_cAgencia	:=	Substr(cBuffer,018,04)
				_cConta  	:=	Substr(cBuffer,030,11)  //Sem o Digito. OBS: Posicao completa seria Substr(cBuffer,30,12)
				_cTipo   	:=	Substr(cBuffer,043,03)
				_cDocument	:=	Substr(cBuffer,151,07) // Numero do Documento
				If _cTipo == "214" //Deposito Identificado (dinheiro/ cheque)
					_cNAGE		:= 	Substr(cBuffer,154,04) // Numero da Agencia Colhedora
					//_cDeposit	:=	ALLTRIM(STR(VAL(Substr(cBuffer,106,32)),30)) // Depositante
					_cDeposit	:=	Substr(cBuffer,106,32) // Depositante
				Else
					_cNAGE		:= 	""
					_cDeposit	:=	Substr(cBuffer,106,32) // Depositante
				Endif
				_cEmissao	:=	Substr(cBuffer,081,06)
				_cData 		:= ctod(SUBSTR(_cEmissao,1,2)+"/"+SUBSTR(_cEmissao,3,2)+"/"+SUBSTR(_cEmissao,5,2))
				_cValor  	:=	Substr(cBuffer,087,18) 
				_dAntServ	:= DATE() - 1 
				  				
				
				// 07/03/2013 - Patricia Fontanezi
				If _cTipo == "209" .AND. _cTpBlq == "0051"
					_cTipo	:= "77"
				Endif
								
				//If _cData < DataValida(_dAntServ,.F.)
				If _cData <> mv_par01
					FT_FSKIP()
					Loop
				Endif

			/*|--------------------------------------------------------------------------------|
			  | Pesquisa registros do arquivo TXT na base ZCG com a chave                      |
			  | EMISSAO+DOCUMENTO+VALOR+DEPOSITANTE se achou não importa o registro novamente  |
			  |--------------------------------------------------------------------------------|*/
				cQuery 		:= " SELECT COUNT(*) AS NREG"
				cQuery 		+= " FROM "+RetSQLname('ZCG')+" "
				cQuery 		+= " WHERE D_E_L_E_T_ <> '*' "
				cQuery 		+= " AND ZCG_IMPFLG = 'S' "
				cQuery 		+= " AND ZCG_EMISSA = '"+DTOS(_cData)+"' "
				cQuery 		+= " AND ZCG_NDOC  = '"+_cDocument+"' "
				cQuery 		+= " AND ZCG_DEPOS = '"+Upper(Substr(_cDeposit,1,30))+"' "
				cQuery 		+= " AND ZCG_VALOR  = '"+ALLTRIM(STR((VAL(_cValor)/100),20,2))+"' "
				TcQuery cQuery New Alias "ZCGPESQ"

				If ZCGPESQ->NREG > 0
					FT_FSKIP()
					ZCGPESQ->(DbCloseArea())
					Loop
				Else
					ZCGPESQ->(DbCloseArea())
				Endif

				/*
				//Alterado pelo analista Emerson dia 17/11/11.
				//Acrescentado no campo ZCG_REGIST o comando GETSXENUM("ZCG","ZCG_REGIST") para que o sistema gere automaticamente a numeracao
				
				cQuery := "SELECT ZCG_REGIST, SUBSTRING(ZCG_REGIST,3,15) AS NREG "
				cQuery += "FROM "+RetSQLname('ZCG')+" "
				cQuery += "ORDER BY ZCG_REGIST DESC "
				TcQuery cQuery New Alias "REGTMP"
				*/

				DbSelectArea("SA6")
				DbSetOrder(5) // FILIAL+CONTA
				If DbSeek(xFilial("SA6")+alltrim(str(val(_cConta),10)),.T.)
					If SA6->A6_COD == "237"
						RecLock("ZCG",.T.)
						ZCG->ZCG_FILIAL := xFilial("ZCG")
						ZCG->ZCG_BANCO  := "237"
						ZCG->ZCG_AGENCI := SA6->A6_AGENCIA
						ZCG->ZCG_CONTA  := SA6->A6_NUMCON
						ZCG->ZCG_EMISSA := _cData
						ZCG->ZCG_TIPO   := _cTipo
						ZCG->ZCG_DEPOS  := Upper(_cDeposit)
						ZCG->ZCG_VALOR  := VAL(_cValor)/100
						ZCG->ZCG_NDOC   := _cDocument
						ZCG->ZCG_NAGE   := _cNAGE
						ZCG->ZCG_CCONT  := SA6->A6_CONTABI //Conta Contabil do Banco (Reduzida)
						ZCG->ZCG_REGIST := GETSXENUM("ZCG","ZCG_REGIST") //Right(Str(Year(dDataBase)),2)+strzero((val(REGTMP->NREG)+1),13) //Alterado dia 10/10/07 pelo analista Emerson
						ZCG->ZCG_IMPFLG := "S" //Flag para definir registros Importados
						ZCG->ZCG_HIST   := _cHist
						ZCG->ZCG_SALDO	:= ZCG->ZCG_VALOR
						MsUnLock()
						ConfirmSX8()
					Endif
				Endif

				/*
				DbSelectArea("REGTMP")
				DbCloseArea("REGTMP")
				*/

				FT_FSKIP()
			EndDo
			FT_FUSE()
		Next
	Case aBanco[oLbx1:nAt,2] == "341" .and. aBanco[oLbx1:nAt,1]
		If cEmpant == '03' //RJ
			cDirect    := "\arq_txtrj\tesouraria\Importacao\Itau\"
			cDirectImp := "\arq_txtrj\tesouraria\Importacao\Itau\Debito\"
		Else
			cDirect    := "\arq_txt\tesouraria\Importacao\Itau\"
			cDirectImp := "\arq_txt\tesouraria\Importacao\Itau\Cartao\"		
		Endif
		aDirect    := Directory(cDirect+"*.RET")

		If Empty(adirect)
			MsgAlert("Não existe nenhum arquivo para ser Importado!!!")
			Return
		Endif

		For _nI := 1 To Len(adirect)
			FT_FUSE(cDirect+adirect[_nI,1])
			FT_FGOTOP()
			cBuffer 	:=	Alltrim(FT_FREADLN())

			If Substr(cBuffer,77,3) <> "341"
				alert("Arquivo não Pertence ao Banco Itaú!")
				Return
			Endif

			If Len(cBuffer)< 200 .or. Len(cBuffer)> 200
				alert("Formato do arquivo Inválido!")
				Return
			Endif
		/*|-----------------------------------------------|
		  | Pula o primeiro registro                      |
		  | Cabecalho                                     |
		  |-----------------------------------------------|*/
			FT_FSKIP()
			ProcRegua(FT_FLASTREC())
			_lFirst := .T.

			While !FT_FEOF()
				IncProc("Processando Leitura do Arquivo Texto...")
				cBuffer 	:=	Alltrim(FT_FREADLN())
				_cID	    := Substr(cBuffer,001,1) // 0-Cabecalho; 1-Detalhes; 9-Rodape
				_cTpSaldo   := Substr(cBuffer,042,1) // 0-Saldo Anterior; 2-Saldo Atual
				_cCategoria := Substr(cBuffer,107,1) // Definicao de Credito/ Debito. 1-Debito, 2-Credito. Codigo da Categoria de Lancamento. EX: 201 Deposito
				_cTipo   	:= Substr(cBuffer,107,3) // Pula Tipo 213 - Transferencia entre CC - Realizado via Movimento Bancario
				_cTpBlq		:= Substr(cBuffer,110,04) // Utilizado para detectar codigo 0911 para itens Bloqueados
				_cTpTrf		:= Substr(cBuffer,151,04) // Pula Agencia 0350 - Transferencia entre CC - Realizado via Movimento Bancario
//				_cHist		:= Substr(cBuffer,050,25) // Historico do lancamento pelo Banco
				_cHist		:= ""
			/*|--------------------------------------------------------------------|
			  | Pula os registros de Saldo Anterior e Atual (_cTpSaldo)            |
			  |                      Rodape - 9 (_cID)                             |
			  | registros de Debito também não sao importados - 1xx (_cCategoria)  |
			  |--------------------------------------------------------------------|*/
			  
				If _cTpSaldo $ "0|2" .or. _cID == "9" .or. _cCategoria == "1" .or. ( _cTipo $ "213" .And. _cTpTrf $ "0350" )
					FT_FSKIP()
					Loop
				Endif
				
				_cAgencia	:=	Substr(cBuffer,018,04)
				_cConta  	:=	Substr(cBuffer,036,05)  //Sem o Digito. OBS: Posicao completa seria Substr(cBuffer,36,06)
				_cTipo   	:=	Substr(cBuffer,107,03)
				_cDocument	:=	Substr(cBuffer,161,04) // Numero do Documento
				_cNAGE		:= 	""
				_cDeposit	:=	Substr(cBuffer,050,25) // Depositante
				_cEmissao	:=	Substr(cBuffer,081,06)
				_cData 		:= ctod(SUBSTR(_cEmissao,1,2)+"/"+SUBSTR(_cEmissao,3,2)+"/"+SUBSTR(_cEmissao,5,2))
				_cValor  	:=	Substr(cBuffer,087,18)
 				_dAntServ	:= DATE() - 1
				
				// 07/03/2013 - Patricia Fontanezi
				If _cTipo == "202" .AND. _cTpBlq == "0038"
					_cTipo	:= "22"
				Endif
								
				//If _cData < DataValida(_dAntServ,.F.)
				If _cData <> mv_par01
					FT_FSKIP()
					Loop
				Endif
			/*|--------------------------------------------------------------------------------|
			  | Pesquisa registros do arquivo TXT na base ZCG com a chave                      |
			  | EMISSAO+DOCUMENTO+VALOR+DEPOSITANTE se achou não importa o registro novamente  |
			  |--------------------------------------------------------------------------------|*/
				cQuery 		:= " SELECT COUNT(*) AS NREG"
				cQuery 		+= " FROM "+RetSQLname('ZCG')+" "
				cQuery 		+= " WHERE D_E_L_E_T_ <> '*' "
				cQuery 		+= " AND ZCG_IMPFLG = 'S' "
				cQuery 		+= " AND ZCG_EMISSA = '"+DTOS(_cData)+"' "
				cQuery 		+= " AND ZCG_NDOC  = '"+_cDocument+"' "
				cQuery 		+= " AND ZCG_DEPOS = '"+Upper(Substr(_cDeposit,1,30))+"' "
				cQuery 		+= " AND ZCG_VALOR  = '"+ALLTRIM(STR((VAL(_cValor)/100),20,2))+"' "
				TcQuery cQuery New Alias "ZCGPESQ"

				If ZCGPESQ->NREG > 0
					FT_FSKIP()
					ZCGPESQ->(DbCloseArea())
					Loop
				Else
					ZCGPESQ->(DbCloseArea())
				Endif

				/*
				//Alterado pelo analista Emerson dia 17/11/11.
				//Acrescentado no campo ZCG_REGIST o comando GETSXENUM("ZCG","ZCG_REGIST") para que o sistema gere automaticamente a numeracao

				cQuery := "SELECT ZCG_REGIST, SUBSTRING(ZCG_REGIST,3,15) AS NREG "
				cQuery += "FROM "+RetSQLname('ZCG')+" "
				cQuery += "ORDER BY ZCG_REGIST DESC "
				TcQuery cQuery New Alias "REGTMP"
				*/

				DbSelectArea("SA6")
				DbSetOrder(5) // FILIAL+CONTA
				If DbSeek(xFilial("SA6")+alltrim(str(val(_cConta),10)),.T.)
					If SA6->A6_COD == "341"
						RecLock("ZCG",.T.)
						ZCG->ZCG_FILIAL := xFilial("ZCG")
						ZCG->ZCG_BANCO  := "341"
						ZCG->ZCG_AGENCI := SA6->A6_AGENCIA
						ZCG->ZCG_CONTA  := SA6->A6_NUMCON
						ZCG->ZCG_EMISSA := _cData
						ZCG->ZCG_TIPO   := _cTipo
						ZCG->ZCG_DEPOS  := Upper(_cDeposit)
						ZCG->ZCG_VALOR  := VAL(_cValor)/100
						ZCG->ZCG_NDOC   := _cDocument
						ZCG->ZCG_NAGE   := _cNAGE
						ZCG->ZCG_CCONT  := SA6->A6_CONTABI //Conta Contabil do Banco (Reduzida)
						ZCG->ZCG_REGIST := GETSXENUM("ZCG","ZCG_REGIST") //Right(Str(Year(dDataBase)),2)+strzero((val(REGTMP->NREG)+1),13) //Alterado dia 10/10/07 pelo analista Emerson
						ZCG->ZCG_IMPFLG := "S" //Flag para definir registros Importados
						ZCG->ZCG_HIST   := _cHist
						ZCG->ZCG_SALDO	:= ZCG->ZCG_VALOR
						MsUnLock()
						ConfirmSX8()
					Endif
				Endif

				/*
				DbSelectArea("REGTMP")
				DbCloseArea("REGTMP")
				*/

				FT_FSKIP()
			EndDo
			FT_FUSE()
		Next
	Case aBanco[oLbx1:nAt,2] == "356" .and. aBanco[oLbx1:nAt,1]
		If cEmpant == '03' //RJ
			cDirect    := "\arq_txtrj\tesouraria\Importacao\Real ABN\"
			cDirectImp := "\arq_txtrj\tesouraria\Importacao\Real ABN\Backup\"
		Else
			cDirect    := "\arq_txt\tesouraria\Importacao\Real ABN\"
			cDirectImp := "\arq_txt\tesouraria\Importacao\Real ABN\Backup\"		
		Endif
		aDirect    := Directory(cDirect+"*.TXT")

		If Empty(adirect)
			MsgAlert("Não existe nenhum arquivo para ser Importado!!!")
			Return
		Endif

		For _nI := 1 To Len(adirect)
			FT_FUSE(cDirect+adirect[_nI,1])
			FT_FGOTOP()
			cBuffer 	:=	Alltrim(FT_FREADLN())

			If Substr(cBuffer,77,3) <> "356"
				alert("Arquivo não Pertence ao Banco Real!")
				Return
			Endif

			If Len(cBuffer)< 200 .or. Len(cBuffer)> 200
				alert("Formato do arquivo Inválido!")
				Return
			Endif
			//|-----------------------------------------------|
			//| Pula o primeiro registro                      |
			//| Cabecalho                                     |
			//|-----------------------------------------------|
			FT_FSKIP()
			ProcRegua(FT_FLASTREC())
			_lFirst := .T.

			While !FT_FEOF()
				IncProc("Processando Leitura do Arquivo Texto...")
				cBuffer 	:=	Alltrim(FT_FREADLN())
				_cID	    := Substr(cBuffer,001,1) // 0-Cabecalho; 1-Detalhes; 9-Rodape
				_cTpSaldo   := Substr(cBuffer,042,1) // 0-Saldo Anterior; 2-Saldo Atual
				_cCategoria := Substr(cBuffer,105,1) // Definicao de Credito/ Debito. D-Debito, C-Credito.
				_cTipo   	:= Substr(cBuffer,043,3) // Pula Tipo 213 - Transferencia entre CC - Realizado via Movimento Bancario
//				_cTpBlq		:= Substr(cBuffer,046,04) // Utilizado para detectar codigo 0911 para itens Bloqueados
				_cHist		:= ""
				//|--------------------------------------------------------------------|
				//| Pula os registros de Saldo Anterior e Atual (_cTpSaldo)            |
				//|                      Rodape - 9 (_cID)                             |
				//| registros de Debito também não sao importados - 1xx (_cCategoria)  |
				//|--------------------------------------------------------------------|

				If _cTpSaldo $ "0|2" .or. _cID == "9" .or. _cCategoria == "D"
					FT_FSKIP()
					Loop
				Endif

				_cAgencia	:=	Substr(cBuffer,018,04)
				_cConta  	:=	Substr(cBuffer,023,06)  //OBS: Posicao completa seria Substr(cBuffer,22,07) não traz o digito.
				_cTipo   	:=	Substr(cBuffer,043,03)
				_cDocument	:=	Substr(cBuffer,075,06) // Numero do Documento
				_cNAGE		:= 	""
				_cHist		:= Substr(cBuffer,050,25)
				_cDeposit	:= ""
				_cEmissao	:=	Substr(cBuffer,081,06)
				_cData 		:= ctod(SUBSTR(_cEmissao,1,2)+"/"+SUBSTR(_cEmissao,3,2)+"/"+SUBSTR(_cEmissao,5,2))
				_cValor  	:=	Substr(cBuffer,087,18)
				_dAntServ	:= DATE() - 1

				//If _cData < DataValida(_dAntServ,.F.)
				If _cData <> mv_par01
					FT_FSKIP()
					Loop
				Endif

				//|--------------------------------------------------------------------------------|
				//| Pesquisa registros do arquivo TXT na base ZCG com a chave                      |
				//| EMISSAO+DOCUMENTO+VALOR+DEPOSITANTE se achou não importa o registro novamente  |
				//|--------------------------------------------------------------------------------|
				cQuery 		:= " SELECT COUNT(*) AS NREG"
				cQuery 		+= " FROM "+RetSQLname('ZCG')+" "
				cQuery 		+= " WHERE D_E_L_E_T_ <> '*' "
				cQuery 		+= " AND ZCG_IMPFLG = 'S' "
				cQuery 		+= " AND ZCG_EMISSA = '"+DTOS(_cData)+"' "
				cQuery 		+= " AND ZCG_NDOC  = '"+_cDocument+"' "
				cQuery 		+= " AND ZCG_DEPOS = '"+Upper(Substr(_cDeposit,1,30))+"' "
				cQuery 		+= " AND ZCG_VALOR  = '"+ALLTRIM(STR((VAL(_cValor)/100),20,2))+"' "
				TcQuery cQuery New Alias "ZCGPESQ"

				If ZCGPESQ->NREG > 0
					FT_FSKIP()
					ZCGPESQ->(DbCloseArea())
					Loop
				Else
					ZCGPESQ->(DbCloseArea())
				Endif

				/*
				//Alterado pelo analista Emerson dia 17/11/11.
				//Acrescentado no campo ZCG_REGIST o comando GETSXENUM("ZCG","ZCG_REGIST") para que o sistema gere automaticamente a numeracao

				cQuery := "SELECT ZCG_REGIST, SUBSTRING(ZCG_REGIST,3,15) AS NREG "
				cQuery += "FROM "+RetSQLname('ZCG')+" "
				cQuery += "ORDER BY ZCG_REGIST DESC "
				TcQuery cQuery New Alias "REGTMP"
				*/

				DbSelectArea("SA6")
				DbSetOrder(5) // FILIAL+CONTA
				If DbSeek(xFilial("SA6")+alltrim(str(val(_cConta),10)),.T.)
					If SA6->A6_COD == "356"
						RecLock("ZCG",.T.)
						ZCG->ZCG_FILIAL := xFilial("ZCG")
						ZCG->ZCG_BANCO  := "356"
						ZCG->ZCG_AGENCI := SA6->A6_AGENCIA
						ZCG->ZCG_CONTA  := SA6->A6_NUMCON
						ZCG->ZCG_EMISSA := _cData
						ZCG->ZCG_TIPO   := _cTipo
						ZCG->ZCG_DEPOS  := Upper(_cDeposit)
						ZCG->ZCG_VALOR  := VAL(_cValor)/100
						ZCG->ZCG_NDOC   := _cDocument
						ZCG->ZCG_NAGE   := _cNAGE
						ZCG->ZCG_CCONT  := SA6->A6_CONTABI //Conta Contabil do Banco (Reduzida)
						ZCG->ZCG_REGIST := GETSXENUM("ZCG","ZCG_REGIST") //Right(Str(Year(dDataBase)),2)+strzero((val(REGTMP->NREG)+1),13) //Alterado dia 10/10/07 pelo analista Emerson
						ZCG->ZCG_IMPFLG := "S" //Flag para definir registros Importados
						ZCG->ZCG_HIST   := _cHist
						ZCG->ZCG_SALDO	:= ZCG->ZCG_VALOR
						MsUnLock()
						ConfirmSX8()
					Endif
				Endif

				/*
				DbSelectArea("REGTMP")
				DbCloseArea("REGTMP")
				*/

				FT_FSKIP()
			EndDo
			FT_FUSE()
		Next
	Case aBanco[oLbx1:nAt,2] == "104" .and. aBanco[oLbx1:nAt,1]
		If cEmpant == '03' //RJ
			cDirect    := "\arq_txtrj\tesouraria\Importacao\BancoCEF\"
			cDirectImp := "\arq_txtrj\tesouraria\Importacao\BancoCEF\Backup\"
		Else
			cDirect    := "\arq_txt\tesouraria\Importacao\BancoCEF\"
			cDirectImp := "\arq_txt\tesouraria\Importacao\BancoCEF\Backup\"		
		Endif
		aDirect    := Directory(cDirect+"*.RET")

		If Empty(adirect)
			MsgAlert("Não existe nenhum arquivo para ser Importado!!!")
			Return
		Endif

		For _nI := 1 To Len(adirect)
			FT_FUSE(cDirect+adirect[_nI,1])
			FT_FGOTOP()
			cBuffer 	:=	FT_FREADLN()

			If Substr(cBuffer,1,3) <> "104"
				alert("Arquivo não Pertence ao Banco CEF!")
				Return
			Endif

			If Len(cBuffer)< 240 .or. Len(cBuffer)> 240
				alert("Formato do arquivo Inválido!")
				Return
			Endif
		/*|-----------------------------------------------|
		  | Pula o primeiro registro                      |
		  | Cabecalho                                     |
		  |-----------------------------------------------|*/
			FT_FSKIP()
			ProcRegua(FT_FLASTREC())
			_lFirst := .T.

			While !FT_FEOF()
				IncProc("Processando Leitura do Arquivo Texto...")
				cBuffer 	:=	Alltrim(FT_FREADLN())
				_cID	    := Substr(cBuffer,008,01) // 0-Cabecalho; 1-Cabecalho Lote (saldo anterior); 3-Detalhes; 5-Rodape Lote (saldo atual); 9-Rodape Arquivo
				_cTpLanc    := Substr(cBuffer,169,01) // Definicao do Tipo de Lancamento Credito/ Debito. D-Debito, C-Credito.
				_cHist		:= Substr(cBuffer,177,25) // Historico do lancamento pelo Banco
			/*|--------------------------------------------------------------------|
			  | Pula Cabecalho e Rodape (Arquivo e Lote)                           |
			  | Registros de Debito também não sao importados - D                  |
			  |--------------------------------------------------------------------|*/
				If _cID $ "0|1|5|9" .or. _cTpLanc == "D"
					FT_FSKIP()
					Loop
				Endif

				_cAgencia	:=	Substr(cBuffer,054,04)
				_cConta  	:=	Substr(cBuffer,065,06) // Sem o Digito.
				_cTipo		:=	Substr(cBuffer,170,03) // Codigos de Categoria
				_cEmissao	:=	Substr(cBuffer,143,08)
				_cData 		:=	ctod(SUBSTR(_cEmissao,1,2)+"/"+SUBSTR(_cEmissao,3,2)+"/"+SUBSTR(_cEmissao,7,2))
				_cValor  	:=	Substr(cBuffer,151,18)                
   				_dAntServ	:= DATE() - 1
								
				//If _cData < DataValida(_dAntServ,.F.)
				If _cData <> mv_par01
					FT_FSKIP()
					Loop
				Endif
				
				_cDeposit	:=	""
				_cDocument	:=	""

//				_cDeposit	:=	ALLTRIM(STR(VAL(Substr(cBuffer,136,15)),30))  // CNPJ do Depositante
				_cDocument	:=	Substr(cBuffer,202,15)   // Numero do Documento 

			/*|--------------------------------------------------------------------------------|
			  | Pesquisa registros do arquivo TXT na base ZCG com a chave                      |
			  | EMISSAO+DOCUMENTO+VALOR+DEPOSITANTE se achou não importa o registro novamente  |
			  |--------------------------------------------------------------------------------|*/
				cQuery := " SELECT COUNT(*) AS NREG"
				cQuery += " FROM "+RetSQLname('ZCG')+" "
				cQuery += " WHERE D_E_L_E_T_ <> '*' "
				cQuery += " AND ZCG_IMPFLG = 'S' "
				cQuery += " AND ZCG_EMISSA = '"+DTOS(_cData)+"' "
				cQuery += " AND ZCG_NDOC  = '"+_cDocument+"' "
				cQuery += " AND ZCG_DEPOS = '"+Upper(Substr(_cDeposit,1,30))+"' "
				cQuery += " AND ZCG_VALOR  = '"+ALLTRIM(STR((VAL(_cValor)/100),20,2))+"' "
				TcQuery cQuery New Alias "ZCGPESQ"

				If ZCGPESQ->NREG > 0
					FT_FSKIP()
					ZCGPESQ->(DbCloseArea())
					Loop
				Else
					ZCGPESQ->(DbCloseArea())
				Endif

				/*
				//Alterado pelo analista Emerson dia 17/11/11.
				//Acrescentado no campo ZCG_REGIST o comando GETSXENUM("ZCG","ZCG_REGIST") para que o sistema gere automaticamente a numeracao

				cQuery := "SELECT ZCG_REGIST, SUBSTRING(ZCG_REGIST,3,15) AS NREG "
				cQuery += "FROM "+RetSQLname('ZCG')+" "
				cQuery += "ORDER BY ZCG_REGIST DESC "
				TcQuery cQuery New Alias "REGTMP"
				*/

				DbSelectArea("SA6")
				DbSetOrder(5) // FILIAL+CONTA
				If DbSeek(xFilial("SA6")+alltrim(str(val(_cConta),10)),.T.)
					If SA6->A6_COD == "104"
						RecLock("ZCG",.T.)
						ZCG->ZCG_FILIAL := xFilial("ZCG")
						ZCG->ZCG_BANCO  := "104"
						ZCG->ZCG_AGENCI := SA6->A6_AGENCIA
						ZCG->ZCG_CONTA  := SA6->A6_NUMCON
						ZCG->ZCG_EMISSA := _cData
						ZCG->ZCG_TIPO   := _cTipo
						ZCG->ZCG_DEPOS  := Upper(_cDeposit)
						ZCG->ZCG_VALOR  := VAL(_cValor)/100
						ZCG->ZCG_NDOC   := _cDocument
						ZCG->ZCG_CCONT  := SA6->A6_CONTABI //Conta Contabil do Banco (Reduzida)
						ZCG->ZCG_REGIST := GETSXENUM("ZCG","ZCG_REGIST") //Right(Str(Year(dDataBase)),2)+strzero((val(REGTMP->NREG)+1),13)
						ZCG->ZCG_IMPFLG := "S" //Flag para definir registros Importados
						ZCG->ZCG_HIST   := _cHist
						ZCG->ZCG_SALDO	:= ZCG->ZCG_VALOR
						MsUnLock()
						ConfirmSX8()
					Endif
				Endif

				/*
				DbSelectArea("REGTMP")
				DbCloseArea("REGTMP")
				*/

				FT_FSKIP()
			EndDo
			FT_FUSE()
		Next
	Case aBanco[oLbx1:nAt,2] == "033" .and. aBanco[oLbx1:nAt,1]
		If cEmpant == '03' //RJ
			cDirect    := "\arq_txtrj\tesouraria\Importacao\BancoSantanderBanespa\"
			cDirectImp := "\arq_txtrj\tesouraria\Importacao\BancoSantanderBanespa\Backup\"
		Else
			cDirect    := "\arq_txt\tesouraria\Importacao\BancoSantanderBanespa\"
			cDirectImp := "\arq_txt\tesouraria\Importacao\BancoSantanderBanespa\Backup\"		
		Endif
		aDirect    := Directory(cDirect+"*.TXT")

		If Empty(adirect)
			MsgAlert("Não existe nenhum arquivo para ser Importado!!!")
			Return
		Endif

		For _nI := 1 To Len(adirect)
			FT_FUSE(cDirect+adirect[_nI,1])
			FT_FGOTOP()
			cBuffer 	:=	FT_FREADLN()

			If Substr(cBuffer,1,3) <> "033"
				alert("Arquivo não Pertence ao Banco Santander Banespa!")
				Return
			Endif

			If Len(cBuffer)< 240 .or. Len(cBuffer)> 240
				alert("Formato do arquivo Inválido!")
				Return
			Endif
		/*|-----------------------------------------------|
		  | Pula o primeiro registro                      |
		  | Cabecalho                                     |
		  |-----------------------------------------------|*/
			FT_FSKIP()
			ProcRegua(FT_FLASTREC())
			_lFirst := .T.

			While !FT_FEOF()
				IncProc("Processando Leitura do Arquivo Texto...")
				cBuffer 	:=	Alltrim(FT_FREADLN())
				_cID	    := Substr(cBuffer,008,01) // 0-Cabecalho; 1-Cabecalho Lote (saldo anterior); 3-Detalhes; 5-Rodape Lote (saldo atual); 9-Rodape Arquivo
				_cTpLanc    := Substr(cBuffer,169,01) // Definicao do Tipo de Lancamento Credito/ Debito. D-Debito, C-Credito.
				_cHist		:= Substr(cBuffer,177,25) // Historico do lancamento pelo Banco
			/*|--------------------------------------------------------------------|
			  | Pula Cabecalho e Rodape (Arquivo e Lote)                           |
			  | Registros de Debito também não sao importados - D                  |
			  |--------------------------------------------------------------------|*/
				If _cID $ "0|1|5|9" .or. _cTpLanc == "D"
					FT_FSKIP()
					Loop
				Endif

				_cAgencia	:=	Substr(cBuffer,054,04)
				_cConta  	:=	Substr(cBuffer,065,06) // Sem o Digito.
				_cTipo		:=	Substr(cBuffer,170,03) // Codigos de Categoria
				_cEmissao	:=	Substr(cBuffer,143,08)
				_cData 		:=	ctod(SUBSTR(_cEmissao,1,2)+"/"+SUBSTR(_cEmissao,3,2)+"/"+SUBSTR(_cEmissao,7,2))
				_cValor  	:=	Substr(cBuffer,151,18)
   				_dAntServ	:= DATE() - 1
								
				//If _cData < DataValida(_dAntServ,.F.)
				If _cData <> mv_par01
					FT_FSKIP()
					Loop
				Endif
				  
				_cDeposit	:=	""
				_cDocument	:=	""

//				_cDeposit	:=	ALLTRIM(STR(VAL(Substr(cBuffer,136,15)),30))  // CNPJ do Depositante
				_cDocument	:=	Substr(cBuffer,202,15)   // Numero do Documento 

			/*|--------------------------------------------------------------------------------|
			  | Pesquisa registros do arquivo TXT na base ZCG com a chave                      |
			  | EMISSAO+DOCUMENTO+VALOR+DEPOSITANTE se achou não importa o registro novamente  |
			  |--------------------------------------------------------------------------------|*/
				cQuery 		:= " SELECT COUNT(*) AS NREG"
				cQuery 		+= " FROM "+RetSQLname('ZCG')+" "
				cQuery 		+= " WHERE D_E_L_E_T_ <> '*' "
				cQuery 		+= " AND ZCG_IMPFLG = 'S' "
				cQuery 		+= " AND ZCG_EMISSA = '"+DTOS(_cData)+"' "
				cQuery 		+= " AND ZCG_NDOC  = '"+_cDocument+"' "
				cQuery 		+= " AND ZCG_DEPOS = '"+Upper(Substr(_cDeposit,1,30))+"' "
				cQuery 		+= " AND ZCG_VALOR  = '"+ALLTRIM(STR((VAL(_cValor)/100),20,2))+"' "
				TcQuery cQuery New Alias "ZCGPESQ"

				If ZCGPESQ->NREG > 0
					FT_FSKIP()
					ZCGPESQ->(DbCloseArea())
					Loop
				Else
					ZCGPESQ->(DbCloseArea())
				Endif

				/*
				//Alterado pelo analista Emerson dia 17/11/11.
				//Acrescentado no campo ZCG_REGIST o comando GETSXENUM("ZCG","ZCG_REGIST") para que o sistema gere automaticamente a numeracao

				cQuery := "SELECT ZCG_REGIST, SUBSTRING(ZCG_REGIST,3,15) AS NREG "
				cQuery += "FROM "+RetSQLname('ZCG')+" "
				cQuery += "ORDER BY ZCG_REGIST DESC "
				TcQuery cQuery New Alias "REGTMP"
				*/

				DbSelectArea("SA6")
				DbSetOrder(5) // FILIAL+CONTA
				If DbSeek(xFilial("SA6")+alltrim(str(val(_cConta),10)),.T.)
					If SA6->A6_COD == "033"
						RecLock("ZCG",.T.)
						ZCG->ZCG_FILIAL := xFilial("ZCG")
						ZCG->ZCG_BANCO  := "033"
						ZCG->ZCG_AGENCI := SA6->A6_AGENCIA
						ZCG->ZCG_CONTA  := SA6->A6_NUMCON
						ZCG->ZCG_EMISSA := _cData
						ZCG->ZCG_TIPO   := _cTipo
						ZCG->ZCG_DEPOS  := Upper(_cDeposit)
						ZCG->ZCG_VALOR  := VAL(_cValor)/100
						ZCG->ZCG_NDOC   := _cDocument
						ZCG->ZCG_CCONT  := SA6->A6_CONTABI //Conta Contabil do Banco (Reduzida)
						ZCG->ZCG_REGIST := GETSXENUM("ZCG","ZCG_REGIST") //Right(Str(Year(dDataBase)),2)+strzero((val(REGTMP->NREG)+1),13)
						ZCG->ZCG_IMPFLG := "S" //Flag para definir registros Importados
						ZCG->ZCG_HIST   := _cHist
						ZCG->ZCG_SALDO	:= ZCG->ZCG_VALOR
						MsUnLock()
						ConfirmSX8()
					Endif
				Endif

				/*
				DbSelectArea("REGTMP")
				DbCloseArea("REGTMP")
				*/

				FT_FSKIP()
			EndDo
			FT_FUSE()
		Next
	EndCase

//Copia e Deleta o arquivo da pasta Origem para a pasta Importado. De qualquer Banco
	For _nI := 1 To Len(adirect)
		If aBanco[oLbx1:nAt,2] == "341"
			__copyfile(cDirect+adirect[_nI,1],cDirectImp+adirect[_nI,1])
			If cEmpant == '03' //RJ
				cDirecCartao:= "\arq_txtrj\tesouraria\Importacao\Itau\Debito\"
			Else
				cDirecCartao:= "\arq_txt\tesouraria\Importacao\Itau\Cartao\"			
			Endif
			__copyfile(cDirect+adirect[_nI,1],cDirecCartao+adirect[_nI,1])
			ferase(cDirect+adirect[_nI,1])
		ElseIf aBanco[oLbx1:nAt,2] == "237"
			__copyfile(cDirect+adirect[_nI,1],cDirectImp+adirect[_nI,1])
			If cEmpant == '03' //RJ
				cDirecCartao:= "\arq_txtrj\tesouraria\Importacao\Bradesco\Debito\"
			Else
				cDirecCartao:= "\arq_txt\tesouraria\Importacao\Bradesco\Debito\"			
			Endif
			__copyfile(cDirect+adirect[_nI,1],cDirecCartao+adirect[_nI,1])
			ferase(cDirect+adirect[_nI,1])
		ElseIf aBanco[oLbx1:nAt,2] == "001"      // PATRICIA FONTANEZI - 01/2013 INCLUSAO DO BANCO DO BRASIL PARA TRATAMENTO
			__copyfile(cDirect+adirect[_nI,1],cDirectImp+adirect[_nI,1])
			If cEmpant == '03' //RJ
				cDirecCartao:= "\arq_txtrj\tesouraria\Importacao\BancodoBrasil\Debito\"
			Else
				cDirecCartao:= "\arq_txt\tesouraria\Importacao\BancodoBrasil\Debito\"			
			Endif
			__copyfile(cDirect+adirect[_nI,1],cDirecCartao+adirect[_nI,1])
			ferase(cDirect+adirect[_nI,1])
		Else
			__copyfile(cDirect+adirect[_nI,1],cDirectImp+adirect[_nI,1])
			ferase(cDirect+adirect[_nI,1])
		Endif
	Next

	MsgInfo("Importacao Finalizada com Sucesso!!!")

Return


//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK06BXA
Rotina de baixa de créditos
@author  	Andy
@since     	28/04/03
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function CCK06BXA()
Local oOk   := LoadBitmap( GetResources(), "LBOK" )
Local oNo   := LoadBitmap( GetResources(), "LBNO" )
Local cPerg := "CCADK06A  "


aPags:= {}

If Pergunte(cPerg, .T.)

	BeginSQL Alias "ZCGTMP"
		SELECT ZCG.*
			  ,ZCG.R_E_C_N_O_ REGZCG
		FROM %table:ZCG% ZCG
		WHERE ZCG_FILIAL=%xFilial:ZCG%
			AND ZCG_CONTA BETWEEN %Exp:mv_par02% AND %Exp:mv_par03%
			AND ZCG_EMISSA BETWEEN %Exp:mv_par04% AND %Exp:mv_par05%
			AND ZCG_SALDO > 0
			AND ZCG.D_E_L_E_T_ = ''
		ORDER BY ZCG_FILIAL
				,ZCG_CONTA
				,ZCG_BANCO
				,ZCG_AGENCI
				,ZCG_EMISSA
				,ZCG_VALOR
	EndSQL	
								
	While ZCGTMP->(!Eof())     

		_cTipoDoc := LEFT(POSICIONE("SZ9",2,xFilial("SZ9")+ZCGTMP->ZCG_TIPO,"Z9_TIPO_D"),15)
		_cAgencia := POSICIONE("SZA",1,xFilial("SZA")+ZCGTMP->ZCG_NAGE,"ZA_NAGE_D")
		_cIdentif := LEFT(POSICIONE("SZB",1,xFilial("SZB")+ZCGTMP->ZCG_IDENT,"ZB_IDENT_D"),10)
		
		aAdd(aPags,{.F.,;
					ZCGTMP->ZCG_EMISSA,;
					ZCGTMP->ZCG_TIPO+" - "+_cTipoDoc,;
					ZCGTMP->ZCG_DEPOS,;
					ZCGTMP->ZCG_VALOR,;
					ZCGTMP->ZCG_NDOC,;
					ZCGTMP->ZCG_NAGE,;
					_cAgencia,;
					ZCGTMP->ZCG_IDENT+" - "+_cIdentif,;
					ZCGTMP->ZCG_BA,;
					ZCGTMP->ZCG_CI,;
					ZCGTMP->ZCG_RDR,;
					ZCGTMP->ZCG_IR,;
					ZCGTMP->ZCG_IRTIP,;
					ZCGTMP->ZCG_IRRDR,;
					ZCGTMP->REGZCG})

	ZCGTMP->(dbSkip())	
	End  
	ZCGTMP->(dbCloseArea()) 

	If Len(aPags) > 0
		
		DEFINE MSDIALOG oDlg FROM  31,58 TO 300,778 TITLE "Escolha de qual movimento quer conciliar " PIXEL
		@ 05,05 LISTBOX oLbx1 FIELDS HEADER "","Data","Tipo/Documento","Depositante","Valor","Documento","No.","Agencia","Identificacao","B.A.","C.I.","RDR","Irregularidade","Tipo Irreg.","RDR Irreg." SIZE 345, 85 OF oDlg PIXEL ;
		ON DBLCLICK ( CCK06M02() )
		
		oLbx1:SetArray(aPags)
		oLbx1:bLine := { || {If(aPags[oLbx1:nAt,1],oOk,oNo),aPags[oLbx1:nAt,2],aPags[oLbx1:nAt,3],aPags[oLbx1:nAt,4],Transform(aPags[oLbx1:nAt,5],"@EZ 999,999,999.99"),aPags[oLbx1:nAt,6],aPags[oLbx1:nAt,7],aPags[oLbx1:nAt,8],aPags[oLbx1:nAt,9],Transform(aPags[oLbx1:nAt,10],"@EZ 999,999,999.99"),Transform(aPags[oLbx1:nAt,11],"@EZ 999,999,999.99"),aPags[oLbx1:nAt,12],Transform(aPags[oLbx1:nAt,13],"@EZ 999,999,999.99"),aPags[oLbx1:nAt,14],aPags[oLbx1:nAt,15] } }
		oLbx1:nFreeze  := 1
		
		//@ 94, 010 BUTTON "Devolução de crédito" SIZE 60 ,12 ACTION ( IF(CCK06DEV(),oDlg:End(),) ) Of oDlg PIXEL
		//@ 94, 090 BUTTON "Gerar Receita CIEE" SIZE 60 ,12 ACTION ( IF(CCK06REC(),oDlg:End(),) ) Of oDlg PIXEL
		@ 94, 264 BUTTON "Marcar" SIZE 25 ,12 ACTION ( CCK06M03() ) Of oDlg PIXEL
		@ 94, 292 BUTTON "Editar" SIZE 25 ,12 ACTION ( IF(CCK06RDR(1),oDlg:End(),) ) Of oDlg PIXEL
		//@ 94, 320 BUTTON ",0
		//Cancelar" SIZE 25 ,12 ACTION ( oDlg:End() ) Of oDlg PIXEL	
		
		ACTIVATE MSDIALOG oDlg CENTERED
	Else
		MsgInfo("Não Haverá Baixa!","Atenção")
	Endif	
EndIf

Return


//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK06M01
Rotina de marcação
@author  	Andy
@since     	28/04/03
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function CCK06M01()

	Local _nI := 0

	If aBanco[oLbx1:nAt,1]
		aBanco[oLbx1:nAt,1] := .F.
	Else
		For _nI := 1 To Len(aBanco)
			aBanco[_nI,1] := .F.
		Next _nI
		aBanco[oLbx1:nAt,1] := .T.
	Endif
	oLbx1:Refresh(.T.)
Return


//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK06M02
Rotina de marcação
@author  	Andy
@since     	28/04/03
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function CCK06M02()

	If aPags[oLbx1:nAt,1]
		aPags[oLbx1:nAt,1] := .F.
	Else
		aPags[oLbx1:nAt,1] := .T.
	Endif

	oLbx1:Refresh(.T.)

Return


//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK06M03
Rotina de marcação
@author  	Andy
@since     	28/04/03
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function CCK06M03()

	Local _nI:= 0

	For _nI:=1 To Len(aPags)
		aPags[nI, 1] := !aPags[nI, 1]
	Next _nI

	oLbx1:Refresh(.T.)

Return


/*/{Protheus.doc} CCK06RDR
Rotina de identificação de créditos x titulos
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/

Static Function CCK06RDR(_nPar)

	Local _nCont := 0
	Local _nCred := 0

	If _nPar == 1

		For _nCont:= 1 To len(aPags)
			If aPags[_nCont,1]
				_nCred++
				ZCG->(dbGoto(aPags[_nCont,16]))
				CCK06CCR()
			Endif
		Next

		If _nCred == 0
			MSGALERT("Nenhum crédito selecionado!")
			Return .F.
		Endif

	Endif

Return .T.


/*/{Protheus.doc} CCK06CCR
Rotina de identificação de créditos x titulos
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
Static Function CCK06CCR()

	Local aAdvSize := MsAdvSize()
	Local aHeader1 := {}
	Local aCols1   := {}
	Local aHeader2 := {}
	Local aCols2   := {}
	Local aCampos  := {}
	Local aFields1 := {"ZCF_TIPO","ZCF_NUM","ZCF_PREFIX","ZCF_PARCEL","ZCF_CLIENT","ZCF_LOJA","ZCF_NOMCLI","ZCF_EMISSA","ZCF_VENCRE",;
		"ZCF_VALOR","ZCF_SALDO","ZCF_CODCTR","ZCF_LOCCTR","ZCF_COMPET","ZCF_IDFATU","ZCF_IDFOLH"}
	Local aButtons := {}
	Local aAlterGD := {"ZCF_BA","ZCF_CI","ZCF_DTPGTO","ZCF_JUROS","ZCF_DESCON"}
	Local nPos     := 0
	Local _cCpoHd  := ""

	Private _cRDR  := SUBSTR(DTOS(DATE()),3,6)
	Private nVlrBA := 0
	Private nVlrCI := 0
	Private nVlrJU := 0
	Private nVlrDE := 0
	Private nVlrSld:= 0
	Private cLbNo  := "LBNO"
	Private cLbOk  := "LBOK"
	Private oGetD1 := nil
	Private oGetD2 := nil
	Private cContrato:= Space(FwTamSX3("ZC1_CODIGO")[1])
	Private cLocCtr  := Space(FwTamSX3("ZCF_LOCCTR")[1])
	Private cIdFolh  := Space(FwTamSX3("ZC7_IDFOL")[1])
	Private cNomDep  := Space(FwTamSX3("ZCG_DEPOS")[1])
	Private dDtFilDe := CtoD("")
	Private dDtFilAte:= CtoD("")
	Private nVlrFil  := 0
	Private cCompetF := Space(FwTamSX3("ZCF_COMPET")[1])
	Private nVlrDepos:= ZCG->ZCG_VALOR
	Private oGetVlBA := nil
	Private oGetVlCI := nil
	Private oGetVlJU := nil
	Private oGetVlDE := nil
	Private oGetSld  := nil
	Private nPsMk    := 1
	Private cIdentif := POSICIONE("SZB",3,xFilial("SZB")+__CUSERID,"ZB_IDENT")
	Private cDesIdent:= POSICIONE("SZB",3,xFilial("SZB")+__CUSERID,"ZB_IDENT_D")
	Private cDeposit := ZCG->ZCG_DEPOS
	Private cObserv  := ""

	aCampos := u_QualCPO("ZCF",aFields1)

	For nPos := 1 To Len(aCampos)

		aAdd(aHeader1,{;
			AllTrim(aCampos[nPos,01]),;
			AllTrim(aCampos[nPos,02]),;
			aCampos[nPos,03],;
			aCampos[nPos,04],;
			aCampos[nPos,05],;
			aCampos[nPos,06],;
			aCampos[nPos,07],;
			aCampos[nPos,08],;
			aCampos[nPos,09],;
			aCampos[nPos,10],;
			aCampos[nPos,11],;
			aCampos[nPos,12],;
			aCampos[nPos,13],;
			aCampos[nPos,14],;
			aCampos[nPos,15],;
			aCampos[nPos,16],;
			aCampos[nPos,17],;
			aCampos[nPos,18]})
	Next

	aAdd(aHeader2,{"","TMP_XMARK","@BMP",1,0,"",,"C","","V","","",,"V","",,})

	nPsMk:= ASCAN(aHeader2,{|x| trim(x[2])=="TMP_XMARK"  })

	aCampos := u_QualCPO("ZCF",,,,.T.)

	For nPos := 1 To Len(aCampos)
		_cCpoHd:= AllTrim(aCampos[nPos,02])
		If _cCpoHd$"ZCF_BA|ZCF_CI|ZCF_JUROS|ZCF_DESCON|ZCF_DTPGTO"
			aAdd(aHeader2,{AllTrim(aCampos[nPos,01]),;
				_cCpoHd,;
				aCampos[nPos,03],;
				aCampos[nPos,04],;
				aCampos[nPos,05],;
				"U_CCK06FOK()",;
				aCampos[nPos,07],;
				aCampos[nPos,08],;
				aCampos[nPos,09],;
				aCampos[nPos,10],;
				aCampos[nPos,11],;
				aCampos[nPos,12],;
				"U_CCK06WHN()",;
				aCampos[nPos,14],;
				aCampos[nPos,15],;
				aCampos[nPos,16],;
				aCampos[nPos,17],;
				aCampos[nPos,18]})
		Else
			aAdd(aHeader2,{AllTrim(aCampos[nPos,01]),;
				_cCpoHd,;
				aCampos[nPos,03],;
				aCampos[nPos,04],;
				aCampos[nPos,05],;
				aCampos[nPos,06],;
				aCampos[nPos,07],;
				aCampos[nPos,08],;
				aCampos[nPos,09],;
				aCampos[nPos,10],;
				aCampos[nPos,11],;
				aCampos[nPos,12],;
				aCampos[nPos,13],;
				aCampos[nPos,14],;
				aCampos[nPos,15],;
				aCampos[nPos,16],;
				aCampos[nPos,17],;
				aCampos[nPos,18]})
		Endif
	Next

//Filtro pelo valor do deposito
	CCK06ATU( aHeader1, @aCols1,,,,,,,ZCG->ZCG_VALOR)

//Filtro pelo nome de depositante
	CCK06ATU( aHeader1, @aCols1,,,,,,ZCG->ZCG_DEPOS)

//Filtro movimento já identificado de acordo com RDR
	CCK06IDE( aHeader2, @aCols2)

/*
//Filtro pela base histórica
//TODO - Criar campo de controle no titulo RA para guardar o código do deposito e RDR 
CCK06ATU( aHeader1, @aCols1,,,,,,M->ZCG_DEPOS)
*/

	DEFINE MSDIALOG oTela TITLE "CNI - Créditos não Identificados" FROM aAdvSize[7],aAdvSize[1] To aAdvSize[6],aAdvSize[5] OF oMainWnd PIXEL STYLE DS_SYSMODAL

	EnchoiceBar(oTela,{|| Iif(CCK06GRV(),oTela:End(),)},{|| oTela:End() },,aButtons)

	oLayer:= FWLayer():new()
	oLayer:Init(oTela,.F.,.T.)
	oLayer:addLine('PARAM',20, .T. )
	oLayer:addLine('MOVIM',30, .T. )
	oLayer:addLine('CREDI',10, .T. )
	oLayer:addLine('SELEC',40, .T. )

	oPnl01:= oLayer:getLinePanel('PARAM')
	@ 02,5 SAY "Contrato:" SIZE 100,10 OF oPnl01 PIXEL
	@ 12,5 MSGET cContrato SIZE 100,10 F3 "ZC0" VALID(VAZIO() .or. ExistCPO('ZC0',cContrato,1) ) OF oPnl01 PIXEL

	@ 27,5 SAY "Local do contrato:" SIZE 100,10 OF oPnl01 PIXEL
	@ 37,5 MSGET cLocCtr SIZE 100,10 F3 "ZC1" VALID(VAZIO() .or. ExistCPO('ZC1',cContrato+cLocCtr,1) ) OF oPnl01 PIXEL

	@ 02,120 SAY "Data De:" SIZE 100,10 OF oPnl01 PIXEL
	@ 12,120 MSGET dDtFilDe SIZE 100,10 OF oPnl01 PIXEL

	@ 27,120 SAY "Data até:" SIZE 100,10 OF oPnl01 PIXEL
	@ 37,120 MSGET dDtFilAte SIZE 100,10 OF oPnl01 PIXEL

	@ 02,235 SAY "Nome Depositante:" SIZE 100,10 OF oPnl01 PIXEL
	@ 12,235 MSGET cNomDep SIZE 250,10 OF oPnl01 PIXEL

	@ 27,235 SAY "Valor:" SIZE 50,10 OF oPnl01 PIXEL
	@ 37,235 MSGET nVlrFil PICTURE PESQPICT("SE1","E1_VALOR") SIZE 50,10 OF oPnl01 PIXEL

	@ 27,290 SAY "Competência:" SIZE 50,10 OF oPnl01 PIXEL
	@ 37,290 MSGET cCompetF SIZE 50,10 OF oPnl01 PIXEL

	@ 27,350 SAY "Id da Folha:" SIZE 100,10 OF oPnl01 PIXEL
	@ 37,350 MSGET cIdFolh SIZE 100,10 F3 "ZC7" VALID(VAZIO() .or. ExistFOL() ) OF oPnl01 PIXEL

	@ 37,470 BUTTON "Filtrar" SIZE 50,12 ACTION ( CCK06ATU( oGetD1:AHEADER, @oGetD1:ACOLS ,cContrato,cLocCtr,;
		dDtFilDe,dDtFilAte,cIdFolh,cNomDep,nVlrFil,cCompetF) ) Of oPnl01 PIXEL

	oPnl02:= oLayer:getLinePanel('MOVIM')
	oGetD1:= MsNewGetDados():New(1,1,1,1,0,"AllwaysTrue","AllwaysTrue",,,,999,"AllwaysTrue()",,,oPnl02,aHeader1,aCols1)
	oGetD1:oBrowse:blDblClick 	:= {|| CCK06ADI() }
	oGetD1:oBrowse:Align:= CONTROL_ALIGN_ALLCLIENT

	oPnl03:= oLayer:getLinePanel('CREDI')

	@ 01,005 SAY "Valor do Depósito:" SIZE 70,10 OF oPnl03 PIXEL
	@ 10,005 MSGET nVlrDepos SIZE 70,10 PICTURE PESQPICT("ZCG","ZCG_VALOR") WHEN .F. OF oPnl03 PIXEL

	@ 01,80 SAY "Valor BA:" SIZE 70,10 OF oPnl03 PIXEL
	@ 10,80 MSGET oGetVlBA var nVlrBA SIZE 70,10 PICTURE PESQPICT("SE1","E1_SALDO") WHEN .F. OF oPnl03 PIXEL

	@ 01,160 SAY "Valor CI:" SIZE 70,10 OF oPnl03 PIXEL
	@ 10,160 MSGET oGetVlCI var nVlrCI SIZE 70,10 PICTURE PESQPICT("SE1","E1_SALDO") WHEN .F. OF oPnl03 PIXEL

	@ 01,240 SAY "Valor Juros:" SIZE 70,10 OF oPnl03 PIXEL
	@ 10,240 MSGET oGetVlJU var nVlrJU SIZE 70,10 PICTURE PESQPICT("SE1","E1_SALDO") WHEN .F. OF oPnl03 PIXEL

	@ 01,320 SAY "Valor Desconto:" SIZE 70,10 OF oPnl03 PIXEL
	@ 10,320 MSGET oGetVlDE var nVlrDE SIZE 70,10 PICTURE PESQPICT("SE1","E1_SALDO") WHEN .F. OF oPnl03 PIXEL

	@ 01,400 SAY "Saldo do Depósito:" SIZE 70,10 OF oPnl03 PIXEL
	@ 10,400 MSGET oGetSld var nVlrSld SIZE 70,10 PICTURE PESQPICT("SE1","E1_SALDO") WHEN .F. OF oPnl03 PIXEL

	oPnl04:= oLayer:getLinePanel('SELEC')
	oGetD2:= MsNewGetDados():New(1,1,1,1,GD_DELETE+GD_UPDATE,"AllwaysTrue","AllwaysTrue",,aAlterGD,,999,"AllwaysTrue()",;
		,"U_CCK06EXC()",oPnl04,aHeader2,aCols2)

	If EMPTY(aCols2)
		oGetD2:ACOLS:={}
	Endif

	oGetD2:oBrowse:Align:= CONTROL_ALIGN_ALLCLIENT

	ACTIVATE MSDIALOG oTela CENTERED ON INIT( CCK06UPD(0) )

Return


/*/{Protheus.doc} CCK06ATU
Rotina de atualização da grid de acordo com parametros
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
Static Function CCK06ATU( aHeadAux, aColsAux, cContra, cLocCtr, dDtDe, dDtAte, cIdFolh, cNomCli, nVlrTit,cCompet)

	Local cTab		:= GetNextAlias()
	Local nUsado	:= 0
	Local nLin		:= 0
	Local nCnt		:= 0
	Local cFiltro   := ""
	Local aAux      := {}
	Local cFormPgto := CVALTOCHAR(MV_PAR06)

	Default cContra := ""
	Default cLocCtr := ""
	Default dDtDe   := CTOD("")
	Default dDtAte  := CTOD("")
	Default cIdFolh := ""
	Default cNomCli := ""
	Default nVlrTit := 0
	Default cCompet := ""

	aColsAux:= {}

	If !EMPTY(cContra)
		cFiltro += " AND E1_XIDCNT='"+ cContra +"'"
	Endif

	If !EMPTY(cLocCtr)
		cFiltro += " AND E1_XIDLOC='"+ cLocCtr +"'"
	Endif

	If !EMPTY(dDtDe) .AND. 	!EMPTY(dDtAte)
		cFiltro += " AND E1_EMISSAO BETWEEN '"+ DTOS(dDtDe) +"' AND '"+ DTOS(dDtAte) +"'"
	Endif

	If !EMPTY(cIdFolh)
		cFiltro += " AND E1_XIDFOLH='"+ cIdFolh +"'"
	Endif

	If !EMPTY(cNomCli)
		aAux:= STRTOKARR2(cNomCli," ")
		aEval(aAux,{|x| cFiltro += " AND E1_NOMCLI LIKE '%"+ x +"%'" })
	Endif

	If nVlrTit > 0
		cFiltro += " AND E1_VALOR="+ CVALTOCHAR(nVlrTit)
	Endif

	If !EMPTY(cCompet)
		cFiltro += " AND E1_XCOMPET='"+ cCompet +"'"
	Endif

	If !EMPTY(cFormPgto)
		cFiltro += " AND ZC0_FORPGT='"+cFormPgto+"'"
	Endif

	cFiltro += " AND E1_SALDO > 0"

	cFiltro:= "%" + cFiltro + "%"

	BeginSQL Alias cTab
	SELECT E1_TIPO    AS ZCF_TIPO
			,E1_NUM     AS ZCF_NUM
			,E1_PREFIXO AS ZCF_PREFIX
			,E1_PARCELA AS ZCF_PARCEL
			,E1_CLIENTE AS ZCF_CLIENT
			,E1_LOJA    AS ZCF_LOJA
			,E1_NOMCLI  AS ZCF_NOMCLI
			,E1_EMISSAO AS ZCF_EMISSA
			,E1_VENCREA AS ZCF_VENCRE
			,E1_VALOR   AS ZCF_VALOR
			,E1_SALDO   AS ZCF_SALDO
			,E1_XIDCNT  AS ZCF_CODCTR
			,E1_XIDLOC  AS ZCF_LOCCTR
			,E1_XCOMPET AS ZCF_COMPET
			,E1_XIDFOLH AS ZCF_IDFOLH
			,E1_XIDFATU AS ZCF_IDFATU 
	FROM %TABLE:SE1% SE1
	INNER JOIN %TABLE:ZC0% ZC0 ON ZC0_FILIAL=%xfilial:ZCO%
		//AND ZC0_FORPGT=%Exp:cFormPgto%
		AND ZC0_CODIGO=E1_XIDCNT
		AND ZC0.D_E_L_E_T_=''
	WHERE  E1_FILIAL=%xfilial:SE1%
		AND SE1.D_E_L_E_T_=''
		AND E1_TIPO NOT IN ('DP ','PR ')
		AND E1_TIPO+E1_NUM+E1_PREFIXO+E1_PARCELA NOT IN(
			SELECT ZCF_TIPO+ZCF_NUM+ZCF_PREFIX+ZCF_PARCEL FROM %TABLE:ZCF% ZCF
			WHERE  ZCF_FILIAL=%xfilial:ZCF%
				AND ZCF.D_E_L_E_T_=''
				AND ZCF_FECHAM=''
		)
		%Exp:cFiltro%
	EndSQL

	TCSETFIELD(cTab,"ZCF_EMISSA","D")
	TCSETFIELD(cTab,"ZCF_VENCRE","D")

	While (cTab)->(!Eof())
		nUsado:= len(aHeadAux)
		aAdd(aColsAux,Array(nUsado+1))
		nLin:= len(aColsAux)
		For nCnt:= 1 To nUsado
			If trim(aHeadAux[nCnt][2])=="TMP_XMARK"
				aColsAux[nLin][nCnt]:= cLbNo
			Else
				aColsAux[nLin][nCnt]:= (cTab)->&(aHeadAux[nCnt][2])
			Endif
		NEXT nCntc
		aColsAux[nLin][nUsado+1]:= .F.
		(cTab)->(dbSkip())
	Enddo
	(cTab)->(dbCloseArea())

Return


/*/{Protheus.doc} CCK06IDE
Filtro movimento já identificado de acordo com RDR
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
Static Function CCK06IDE( aHeadAux, aColsAux)

	Local cTab		:= GetNextAlias()
	Local nUsado	:= 0
	Local nLin		:= 0
	Local nCnt		:= 0

	BeginSQL Alias cTab
	SELECT ZCF.R_E_C_N_O_ AS RECZCF FROM %TABLE:ZCF% ZCF			 		 	
	WHERE  ZCF_FILIAL=%xfilial:ZCF%
		AND ZCF.D_E_L_E_T_=''
		AND ZCF_REGIST=%Exp:ZCG->ZCG_REGIST%
		AND ZCF_TIPO!='CRD'
	EndSQL

	TCSETFIELD(cTab,"E1_EMISSAO","D")
	TCSETFIELD(cTab,"E1_VENCREA","D")

	While (cTab)->(!Eof())
		ZCF->(DbGoto((cTab)->RECZCF))
		If ZCF->(!Eof())
			nUsado := len(aHeadAux)
			aAdd(aColsAux,Array(nUsado+1))
			nLin := len(aColsAux)
			For nCnt:= 1 To nUsado
				If trim(aHeadAux[nCnt][2])=="TMP_XMARK"
					aColsAux[nLin][nCnt] := Iif(ZCF->ZCF_BA > 0 .OR. ZCF->ZCF_CI > 0,cLbOk,cLbNo)
				Else
					aColsAux[nLin][nCnt] := ZCF->&(aHeadAux[nCnt][2])
				Endif
			NEXT nCntc
			aColsAux[nLin][nUsado+1] := .F.
		Endif
		(cTab)->(dbSkip())
	Enddo
	(cTab)->(dbCloseArea())

Return


/*/{Protheus.doc} CCK06FOK
Rotina de validação dos campos editáveis
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
User Function CCK06FOK()

	Local cCpo := STRTRAN(READVAR(),"M->","")
	Local nPsS2:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_SALDO" })
	Local cIdenDW3 := ALLTRIM(SuperGetMv("CI_IDENDW3",.F.,"96"))

//Se esta sendo chamado atraves da rotina de validação da DW3, somente permite alterar movimentos da DW3
	If IsInCallStack("U_CCK06DW3")

		nPCOL  := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_IDENT"})
		If ALLTRIM(oGetD2:ACOLS[oGetD2:nAt][nPCOL])<>cIdenDW3
			alert("Somente podem ser editados movimentos da DW3")
			lRet:= .F.
		Endif

	Endif

	If cCpo == "ZCF_DTPGTO"

		If M->ZCF_DTPGTO < DATE() .OR. M->ZCF_DTPGTO != DATAVALIDA(M->ZCF_DTPGTO,.T.)
			MSGALERT( "Informe uma data válida para pagamento!")
			Return .f.
		Endif

	ElseIf cCpo == "ZCF_BA"

		nPsBA:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_BA" })

		If M->ZCF_BA > oGetD2:ACOLS[oGetD2:nAt][nPsS2]
			MSGALERT("O Valor informado é maior que o saldo do titulo!")
			Return .f.
		Endif

		If M->ZCF_BA > 0
			oGetD2:ACOLS[oGetD2:nAt][nPsMk]:= cLbOk
		Else
			oGetD2:ACOLS[oGetD2:nAt][nPsMk]:= cLbNo
		Endif

		nVlrBA:= M->ZCF_BA
		nVlrCI:= 0
		nVlrJU:= 0
		nVlrDE:= 0

		CCK06UPD(oGetD2:nAt)

	ElseIf cCpo == "ZCF_CI"

		nPsCI:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_CI" })
		nPsJ2:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_JUROS" })
		nPsD2:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_DESCON" })

		If M->ZCF_CI > oGetD2:ACOLS[oGetD2:nAt][nPsS2]
			MSGALERT("O Valor informado é maior que o saldo do titulo!")
			Return .f.
		Endif

		If M->ZCF_CI  > 0
			oGetD2:ACOLS[oGetD2:nAt][nPsMk]:= cLbOk
		Else
			oGetD2:ACOLS[oGetD2:nAt][nPsMk]:= cLbNo
		Endif


		nVlrBA:= 0
		nVlrCI:= M->ZCF_CI
		nVlrJU:= oGetD2:ACOLS[oGetD2:nAt][nPsJ2]
		nVlrDE:= oGetD2:ACOLS[oGetD2:nAt][nPsD2]

		CCK06UPD(oGetD2:nAt)


	ElseIf cCpo == "ZCF_JUROS"

		nPsCI:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_CI" })
		nPsJ2:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_JUROS" })
		nPsD2:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_DESCON" })

		If oGetD2:ACOLS[oGetD2:nAt][nPsCI] < oGetD2:ACOLS[oGetD2:nAt][nPsS2]
			MSGALERT("Para informar juros o valor da CI precisa ser igual ao do saldo!")
			Return .f.
		Endif

		If oGetD2:ACOLS[oGetD2:nAt][nPsCI]  > 0
			oGetD2:ACOLS[oGetD2:nAt][nPsMk]:= cLbOk
		Else
			oGetD2:ACOLS[oGetD2:nAt][nPsMk]:= cLbNo
		Endif

		nVlrBA:= 0
		nVlrCI:= oGetD2:ACOLS[oGetD2:nAt][nPsCI]
		nVlrJU:= M->ZCF_JUROS
		nVlrDE:= oGetD2:ACOLS[oGetD2:nAt][nPsD2]

		CCK06UPD(oGetD2:nAt)


	ElseIf cCpo == "ZCF_DESCON"

		nPsCI:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_CI" })
		nPsJ2:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_JUROS" })
		nPsD2:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_DESCON" })

		If oGetD2:ACOLS[oGetD2:nAt][nPsCI] < oGetD2:ACOLS[oGetD2:nAt][nPsS2]
			MSGALERT("Para informar desconto o valor da CI precisa ser igual ao do saldo!")
			Return .f.
		Endif

		If oGetD2:ACOLS[oGetD2:nAt][nPsCI] > 0
			oGetD2:ACOLS[oGetD2:nAt][nPsMk]:= cLbOk
		Else
			oGetD2:ACOLS[oGetD2:nAt][nPsMk]:= cLbNo
		Endif

		nVlrBA:= 0
		nVlrCI:= oGetD2:ACOLS[oGetD2:nAt][nPsCI]
		nVlrJU:= oGetD2:ACOLS[oGetD2:nAt][nPsJ2]
		nVlrDE:= M->ZCF_DESCON

		CCK06UPD(oGetD2:nAt)

	Endif

Return .T.


/*/{Protheus.doc} CCK06UPD
Rotina de atualização dos valores de BA e CI
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
Static Function CCK06UPD(nLin)

	Local nPsBA := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_BA" })
	Local nPsCI := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_CI" })
	Local nPsJ2 := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_JUROS" })
	Local nPsD2 := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_DESCON" })
	Local nCnta := 0

	For nCnta:= 1 To len(oGetD2:ACOLS)

		If nLin > 0 .AND. nLin == nCnta
			LOOP
		Endif

		If oGetD2:ACOLS[nCnta][nPsMk] == cLbOk
			nVlrBA+= oGetD2:ACOLS[nCnta][nPsBA]
			nVlrCI+= oGetD2:ACOLS[nCnta][nPsCI]
			nVlrJU+= oGetD2:ACOLS[nCnta][nPsJ2]
			nVlrDE+= oGetD2:ACOLS[nCnta][nPsD2]
		Endif
	Next

	nVlrSld:= nVlrDepos-(nVlrBA+nVlrCI+nVlrJU-nVlrDE)

	oGetD2:oBrowse:Refresh()
	oGetVlBA:Refresh()
	oGetVlCI:Refresh()
	oGetVlJU:Refresh()
	oGetVlDE:Refresh()
	oGetSld:Refresh()

Return


/*/{Protheus.doc} CCK06WHN
Rotina de X3_WHEN dos campos editáveis
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
User Function CCK06WHN()

	Local cCpo  := STRTRAN(READVAR(),"M->","")
	Local nPTip2:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_TIPO" })
	Local nPFpg := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_FORPGT" })
	Local nPFEch:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_FECHAM" })
	Local nPIDENT:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_IDENT" })
	Local cTpTit:= oGetD2:ACOLS[oGetD2:nAt][nPTip2]
	Local nForpg:= VAL(oGetD2:ACOLS[oGetD2:nAt][nPFpg])
	Local cIdentL:= oGetD2:ACOLS[oGetD2:nAt][nPIDENT]
	Local lFechou:= oGetD2:ACOLS[oGetD2:nAt][nPFEch] == "1"
	Local lRet  := .T.
	Local cIdenDW3 := SuperGetMv("CI_IDENDW3",.F.,"96") //Identificação DW3

	If IsInCallStack("U_CCK06DW3") //Se estiver entrando atraves da tela de validação da DW3

		If  lFechou

			MSGALERT("O registro selecionado já foi fechado e não pode ser editado!!")

			lRet := .F.
		Else
			If alltrim(cIdentL)<>Alltrim(cIdenDW3)
				lRet := .F.
			Endif
		/*
			If alltrim(cIdentL)==Alltrim(cIdenDW3)
				If cTpTit=="PBA" .AND. cCpo$"ZCF_CI|ZCF_JUROS|ZCF_DESCON"
				lRet := .F.
				ElseIf cTpTit!="PBA" .AND. cCpo$"ZCF_BA|ZCF_DTPGTO"
				lRet := .F.
				Endif
			Else
				If cCpo$"ZCF_BA|ZCF_DTPGTO"
				lRet := .F.
				Endif
			Endif
		*/
		Endif

	Else

		If MV_PAR06!=nForpg .OR. lFechou

			If lFechou
				MSGALERT("O registro selecionado já foi fechado e não pode ser editado!!")
			Endif

			lRet := .F.
		Else
			If MV_PAR06==2
				If cTpTit=="PBA" .AND. cCpo$"ZCF_CI|ZCF_JUROS|ZCF_DESCON"
					lRet := .F.
				ElseIf cTpTit!="PBA" .AND. cCpo$"ZCF_BA|ZCF_DTPGTO"
					lRet := .F.
				Endif
			Else
				If cCpo$"ZCF_BA|ZCF_DTPGTO"
					lRet := .F.
				Endif
			Endif
		Endif

	Endif

Return lRet


/*/{Protheus.doc} CCK06ADI
Rotina para adicionar titulos na grid de selecionados
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
Static Function CCK06ADI()

	Local nPTip1 := ASCAN(oGetD1:AHEADER,{|x| TRIM(x[2])=="ZCF_TIPO" })
	Local nPNum1 := ASCAN(oGetD1:AHEADER,{|x| TRIM(x[2])=="ZCF_NUM" })
	Local nPFol1 := ASCAN(oGetD1:AHEADER,{|x| TRIM(x[2])=="ZCF_IDFOLH" })
	Local nPCnt1 := ASCAN(oGetD1:AHEADER,{|x| TRIM(x[2])=="ZCF_CODCTR" })
	Local nPTip2 := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_TIPO" })
	Local nPNum2 := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_NUM" })
	Local nUsado := 0
	Local nLin   := 0
	Local nPos   := 0
	Local nCnt   := 0
	Local cChav  := ""
	Local nTem   := 0
	Local cUnidade:= ""

	If !EMPTY(oGetD1:ACOLS)

		cChav:= oGetD1:ACOLS[oGetD1:NAT][nPTip1] + oGetD1:ACOLS[oGetD1:NAT][nPNum1]

		If !EMPTY(cChav)
			nTem := ASCAN(oGetD2:ACOLS,{|x| x[nPTip2]+x[nPNum2]==cChav })

			If nTem == 0

				ZC0->(Dbsetorder(1))
				ZC0->(DbSeek(xFilial("ZC0") + oGetD1:ACOLS[oGetD1:NAT][nPCnt1] ))

				ZC3->(dbSetOrder(2))
				If ZC3->(dbSeek(xFilial("ZC3") + oGetD1:ACOLS[oGetD1:NAT][nPCnt1] ))
					cUnidade := ZC3->ZC3_UNRESP
				Endif

				nUsado:= len(oGetD2:AHEADER)
				aAdd(oGetD2:ACOLS,Array(nUsado+1))
				nLin:= len(oGetD2:ACOLS)
				For nCnt:= 1 To nUsado
					If trim(oGetD2:AHEADER[nCnt][2])=="TMP_XMARK"
						oGetD2:ACOLS[nLin][nCnt]:= cLbNo
					ElseIf trim(oGetD2:AHEADER[nCnt][2])=="ZCF_RDR"
						oGetD2:ACOLS[nLin][nCnt]:= _cRDR
					ElseIf trim(oGetD2:AHEADER[nCnt][2])=="ZCF_FORPGT"
						oGetD2:ACOLS[nLin][nCnt]:= ZC0->ZC0_FORPGT
					ElseIf trim(oGetD2:AHEADER[nCnt][2])=="ZCF_RMU"
						If ZC0->ZC0_TIPEMP=="2"
							oGetD2:ACOLS[nLin][nCnt]:= "U" 	//U = Publica
						ElseIf ZC0->ZC0_TIPEMP=="1"
							oGetD2:ACOLS[nLin][nCnt]:= "R" 	//R = Privada
						ElseIf ZC0->ZC0_TIPEMP=="3"
							oGetD2:ACOLS[nLin][nCnt]:= "M"		//M = Mista
						Else
							oGetD2:ACOLS[nLin][nCnt]:= "O"		//O = Outras Contribuicoes
						Endif
					ElseIf trim(oGetD2:AHEADER[nCnt][2])=="ZCF_TPSERV"
						If ZC0->ZC0_TIPCON == "1"
							oGetD2:ACOLS[nLin][nCnt]:= "E" 		//E = Estagio
						ElseIf ZC0->ZC0_TIPCON == "2"
							oGetD2:ACOLS[nLin][nCnt]:= "AE" 	//AE = Aprendiz Empregador
						Else
							oGetD2:ACOLS[nLin][nCnt]:= "OS" 	//OS = Outros Servicos
						Endif
					ElseIf trim(oGetD2:AHEADER[nCnt][2])=="ZCF_UNIDAD"
						oGetD2:ACOLS[nLin][nCnt]:= cUnidade
					ElseIf trim(oGetD2:AHEADER[nCnt][2])=="ZCF_DESUNI"
						oGetD2:ACOLS[nLin][nCnt]:= Posicione("ZCN",1,xFilial("ZCN") + cUnidade ,"ZCN_DLocal")
					ElseIf trim(oGetD2:AHEADER[nCnt][2])=="ZCF_IDENT"
						oGetD2:ACOLS[nLin][nCnt]:= cIdentif
					ElseIf trim(oGetD2:AHEADER[nCnt][2])=="ZCF_DIDENT"
						oGetD2:ACOLS[nLin][nCnt]:= cDesIdent
					ElseIf trim(oGetD2:AHEADER[nCnt][2])=="ZCF_BA"
						oGetD2:ACOLS[nLin][nCnt]:= 0
					ElseIf trim(oGetD2:AHEADER[nCnt][2])=="ZCF_CI"
						oGetD2:ACOLS[nLin][nCnt]:= 0
					ElseIf trim(oGetD2:AHEADER[nCnt][2])=="ZCF_DTPGTO"
						oGetD2:ACOLS[nLin][nCnt]:= u_VDtFolha(oGetD1:ACOLS[oGetD1:NAT][nPFol1])
					ElseIf trim(oGetD2:AHEADER[nCnt][2])=="ZCF_JUROS"
						oGetD2:ACOLS[nLin][nCnt]:= 0
					ElseIf trim(oGetD2:AHEADER[nCnt][2])=="ZCF_DESCON"
						oGetD2:ACOLS[nLin][nCnt]:= 0
					ElseIf (nPos:=ASCAN(oGetD1:AHEADER,{|x| x[2]==oGetD2:AHEADER[nCnt][2] }) ) > 0
						oGetD2:ACOLS[nLin][nCnt]:= oGetD1:ACOLS[oGetD1:NAT][nPos]
					Else
						oGetD2:ACOLS[nLin][nCnt]:= Space(FwTamSX3(TRIM(oGetD2:AHEADER[nCnt][2]))[1])
					Endif
				NEXT
				oGetD2:ACOLS[nLin][nUsado+1]:= .F.
				oGetD2:oBrowse:Refresh()
			Else
				MSGALERT("O registro já foi adicionado!")
			Endif
		Else
			ALERT("Não tem registro!")
		Endif
	Else
		ALERT("Não tem registro!")
	Endif

Return


/*/{Protheus.doc} CCK06EXC
Exclui linha da getdados 2
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
User Function CCK06EXC()

	Local nPFEch := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_FECHAM" })
	Local lFechou:= oGetD2:ACOLS[oGetD2:nAt][nPFEch] == "1"
	Local lRet   := .T.
	Local nPCOL  := ""
	Local cIdenDW3 := ALLTRIM(SuperGetMv("CI_IDENDW3",.F.,"96"))

//Se esta sendo chamado atraves da rotina de validação da DW3, somente permite excluir movimentos da DW3
	If IsInCallStack("U_CCK06DW3")

		nPCOL  := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_IDENT"})
		If ALLTRIM(oGetD2:ACOLS[oGetD2:nAt][nPCOL])<>cIdenDW3
			alert("Somente podem ser excluídos movimentos da DW3")
			lRet:= .F.
		Endif

	Endif

	If lFechou
		MSGALERT("O registro já foi fechado e não pode ser excluido!!")
		lRet:= .F.
	Else
		oGetD2:ACOLS[oGetD2:nAt][nPsMk]:= Iif(oGetD2:ACOLS[oGetD2:nAt][nPsMk]==cLbNo,cLbOk,cLbNo)

		nVlrBA:= 0
		nVlrCI:= 0
		nVlrJU:= 0
		nVlrDE:= 0

		CCK06UPD(0)
	Endif

Return lRet


/*/{Protheus.doc} ExistFOL
Valida se existe a folha selecionada
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
Static Function ExistFOL()

	Local lRet:= .T.

	dbSelectArea("ZC7")
	ZC7->(dbSetOrder(1))
	If !ZC7->(dbSeek(cIdFolh))
		lRet:= .F.
		Help("",1,"REGNOIS")
	Endif

Return lRet


/*/{Protheus.doc} CCK06GRV
Rotina de gravação dos créditos identificados
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
Static Function CCK06GRV()

	Local nPNum   := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_NUM" })
	Local nPTipo  := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_TIPO" })
	Local nPPrefix:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_PREFIX" })
	Local nPParcel:= ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_PARCEL" })
	Local nPDtPag := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_DTPGTO" })
	Local nPContr := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_CODCTR" })
	Local nPFolha := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_IDFOLH" })
	Local nPsBA   := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_BA" })
	Local nPsCI   := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_CI" })
	Local nPRDR   := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_RDR" })
	Local nPFpg   := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_FORPGT" })
	Local nPIDENT := ASCAN(oGetD2:AHEADER,{|x| TRIM(x[2])=="ZCF_IDENT" })
	Local nCnta   := 0
	Local nCntb   := 0
	Local nTot    := 0
	Local _lLock  := .F.
	Local _cContra:= ""
	Local _cNumMov:= ""
	Local nForpg  := 0
	Local cIdenDW3 := SuperGetMv("CI_IDENDW3",.F.,"96") //Identificação DW3

	FOR nCnta:= 1 To LEN(oGetD2:ACOLS)
		nTot++

		nForpg:= VAL(oGetD2:ACOLS[nCnta][nPFpg])
		cIdentL:=oGetD2:ACOLS[nCnta][nPIDENT]

		//If MV_PAR06==2 .AND. nForpg == 2
		If Iif(IsInCallStack("U_CCK06DW3"),(alltrim(cIdentL)==Alltrim(cIdenDW3) .AND. nForpg == 2),(MV_PAR06==2 .AND. nForpg == 2))
			If oGetD2:ACOLS[nCnta][nPTipo]=="PBA"

				If (oGetD2:ACOLS[nCnta][nPDtPag] < DATE() .OR. oGetD2:ACOLS[nCnta][nPDtPag] != DATAVALIDA(oGetD2:ACOLS[nCnta][nPDtPag],.T.))

					If IsInCallStack("U_CCK06DW3")
						If !ExistMovZCF(oGetD2:ACOLS[nCnta][nPRDR], oGetD2:ACOLS[nCnta][nPTipo], oGetD2:ACOLS[nCnta][nPNum], oGetD2:ACOLS[nCnta][nPPrefix], oGetD2:ACOLS[nCnta][nPParcel])
							MSGALERT( "Informe uma data válida para pagamento na linha "+ CVALTOCHAR(nCnta) +"!")
							Return .f.
						Endif
					Else
						MSGALERT( "Informe uma data válida para pagamento na linha "+ CVALTOCHAR(nCnta) +"!")
						Return .f.
					Endif

				ElseIf oGetD2:ACOLS[nCnta][nPsBA] == 0

					MSGALERT( "Informe o valor de BA na linha "+ CVALTOCHAR(nCnta) +" ou delete a linha!")
					Return .f.

				Endif
			ElseIf oGetD2:ACOLS[nCnta][nPTipo]!="PBA"

				If oGetD2:ACOLS[nCnta][nPsCI] == 0

					MSGALERT( "Informe o valor de CI na linha "+ CVALTOCHAR(nCnta) +" ou delete a linha!")
					Return .f.

				Endif
			Endif

			//ElseIf MV_PAR06!=2 .AND. nForpg != 2
		ElseIf Iif(IsInCallStack("U_CCK06DW3"),(alltrim(cIdentL)==Alltrim(cIdenDW3) .AND. nForpg != 2),(MV_PAR06!=2 .AND. nForpg != 2))

			If oGetD2:ACOLS[nCnta][nPsCI] == 0

				MSGALERT( "Informe o valor de CI na linha "+ CVALTOCHAR(nCnta) +" ou delete a linha!")
				Return .f.

			Endif

		Endif

	NEXT

	If nTot == 0
		msgalert("Nenhum registro selecionado")
		Return .f.
	Endif

	If MSGYESNO("Confirma a gravação dos créditos identificados ?")

		FOR nCnta:= 1 To LEN(oGetD2:ACOLS)
			If oGetD2:ACOLS[nCnta][nPsMk] == cLbOk
				_cContra:= oGetD2:ACOLS[nCnta][nPContr]
				exit
			Endif
		next

		U_CCK06CRD( _cContra)

		ZCF->(dbSetorder(1)) //ZCF_FILIAL+ZCF_RDR+ZCF_TIPO+ZCF_NUM+ZCF_PREFIX+ZCF_PARCEL

		FOR nCnta:= 1 To LEN(oGetD2:ACOLS)

			nForpg:= VAL(oGetD2:ACOLS[nCnta][nPFpg])
			cIdentL:=oGetD2:ACOLS[nCnta][nPIDENT]
			//If MV_PAR06 == nForpg
			If Iif(IsInCallStack("U_CCK06DW3"),alltrim(cIdentL)==Alltrim(cIdenDW3),MV_PAR06 == nForpg)

				If oGetD2:ACOLS[nCnta][nPsMk] == cLbOk

					_lLock:= !ZCF->(dbseek(xFilial("ZCF") + oGetD2:ACOLS[nCnta][nPRDR] + oGetD2:ACOLS[nCnta][nPTipo] + oGetD2:ACOLS[nCnta][nPNum] +;
						oGetD2:ACOLS[nCnta][nPPrefix] + oGetD2:ACOLS[nCnta][nPParcel] ))

					If _lLock
						_cNumMov := GETSXENUM("ZCF","ZCF_NUMMOV")
						ConfirmSX8()
					Endif

					RecLock("ZCF",_lLock)

					For nCntb:= 1 To LEN(oGetD2:AHEADER)-1
						ZCF->(FieldPut(FieldPos(Trim(oGetD2:AHEADER[nCntb][2])),oGetD2:ACOLS[nCnta][nCntb]))
					NEXT

					ZCF->ZCF_FILIAL	:= xFilial("ZCF")
					ZCF->ZCF_DTMOVI	:= DATE()
					ZCF->ZCF_REGIST := ZCG->ZCG_REGIST
					If IsInCallStack("U_CCK06DW3")
						ZCF->ZCF_RDR := SUBSTR(DTOS(DATE()),3,6)
					Endif

					If _lLock
						ZCF->ZCF_NUMMOV := _cNumMov
					Else
						_cNumMov:= ZCF->ZCF_NUMMOV
					Endif

					MsUnlock()

					If !_lLock
						TCSQLEXEC("UPDATE " + RETSQLNAME("ZCH") + " SET D_E_L_E_T_ <> ' ', R_E_C_D_E_L_ = R_E_C_N_O_ WHERE ZCH_NUMMOV = '" + _cNumMov + "'")
					Endif

					U_CCK06RAT(_cNumMov)

					dbSelectArea("ZC7")
					ZC7->(dbSetOrder(1))
					If ZC7->(dbSeek(oGetD2:ACOLS[nCnta][nPFolha]))
						RecLock("ZC7", .F.)
						ZC7->ZC7_DTPGTO := oGetD2:ACOLS[nCnta][nPDtPag]
						ZC7->ZC7_STATUS := 'L' //Aguardando liberação para calculo
						ZC7->(msUnLock())
					Endif

				Else
					If ZCF->(dbseek(xFilial("ZCF") + oGetD2:ACOLS[nCnta][nPRDR] + oGetD2:ACOLS[nCnta][nPTipo] + oGetD2:ACOLS[nCnta][nPNum] +;
							oGetD2:ACOLS[nCnta][nPPrefix] + oGetD2:ACOLS[nCnta][nPParcel] ))
						RecLock("ZCF",.F.)
						_cNumMov:= ZCF->ZCF_NUMMOV
						DBDELETE()
						MsUnlock()
						If !EMPTY(_cNumMov)
							TCSQLEXEC("UPDATE "+RETSQLNAME("ZCH")+ " SET D_E_L_E_T_='*',R_E_C_D_E_L_=R_E_C_N_O_ WHERE ZCH_NUMMOV='"+_cNumMov+"'")
						Endif

						dbSelectArea("ZC7")
						ZC7->(dbSetOrder(1))
						If ZC7->(dbSeek(oGetD2:ACOLS[nCnta][nPFolha]))
							RecLock("ZC7", .F.)
							ZC7->ZC7_DTPGTO := CTOD("")
							ZC7->ZC7_STATUS := '1' //Aguardando liberação de crédit
							ZC7->(msUnLock())
						Endif

					Endif
				Endif
			Endif
		NEXT

		RecLock("ZCG",.F.)
		ZCG->ZCG_SALDO 	:= nVlrSld
		MsUnLock()
	Else
		Return .f.
	Endif

Return .T.


/*/{Protheus.doc} CCK06CRD
Inclui movimento de crédito
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
User Function CCK06CRD( _cContra)

	Local _cTabMOv := GetNextAlias()
	Local _cTabNum := ""
	Local _cNumMov := ""

//Verifica se já existe o movimento de crédito
	BeginSql Alias _cTabMOv
	SELECT * FROM %TABLE:ZCF% ZCF			 		 	
	WHERE ZCF_FILIAL=%xfilial:ZCF%
		AND ZCF_TIPO = 'CRD' 
		AND ZCF_PREFIX = 'CRD'
		AND ZCF_REGIST = %Exp:ZCG->ZCG_REGIST%
		AND ZCF.D_E_L_E_T_=''	
	EndSql

	If (_cTabMOv)->(Eof())

		_cTabNum := GetNextAlias()

		BeginSql Alias _cTabNum
		SELECT MAX(ZCF_NUM) AS NUM 
		FROM %TABLE:ZCF% ZCF			 		 	
		WHERE ZCF_FILIAL=%xfilial:ZCF%
			AND ZCF_TIPO =  'CRD'
			AND ZCF_PREFIX = 'CRD'
			AND ZCF.D_E_L_E_T_=''	
		EndSql

		_cNumMov := SOMA1((_cTabNum)->NUM)

		(_cTabNum)->(dbCloseArea())

		RecLock("ZCF",.T.)
		ZCF->ZCF_FILIAL    := xFilial("ZCF")
		ZCF->ZCF_DTMOVI	   := DATE()
		ZCF->ZCF_TIPO      := 'CRD'
		ZCF->ZCF_NUM       := _cNumMov
		ZCF->ZCF_PREFIX    := 'CRD'
		ZCF->ZCF_PARCEL    := ""
		ZCF->ZCF_CLIENT    := ""
		ZCF->ZCF_LOJA      := ""
		ZCF->ZCF_NOMCLI    := ""
		ZCF->ZCF_EMISSA    := DDATABASE
		ZCF->ZCF_VENCRE    := DDATABASE
		ZCF->ZCF_VALOR     := ZCG->ZCG_SALDO
		ZCF->ZCF_SALDO     := ZCF->ZCF_VALOR
		ZCF->ZCF_CODCTR    := _cContra
		ZCF->ZCF_LOCCTR    := ""
		ZCF->ZCF_IDFOLH	   := ""
		ZCF->ZCF_COMPET	   := ""
		ZCF->ZCF_REGIST	   := ZCG->ZCG_REGIST

		/*
		ZCF->ZCF_UNIDAD	   := ZCG->ZCG_UNIDAD
		ZCF->ZCF_DESUNI	   := ZCG->ZCG_DESUNI
		ZCF->ZCF_IDENT 	   := ZCG->ZCG_IDENT
		ZCF->ZCF_DIDENT	   := ZCG->ZCG_IDENTD
		ZCF->ZCF_RMU       := ZCG->ZCG_RMU
		ZCF->ZCF_TPSERV    := ZCG->ZCG_TPSERV
		ZCF->ZCF_NAGE  	   := ZCG->ZCG_NAGE
		ZCF->ZCF_DESAGE    := ""
		ZCF->ZCF_OBSERV    := ZCG->ZCG_OBS
		ZCF->ZCF_RDR       := ZCG->ZCG_RDR
		*/

		MsUnlock()

	Endif

	(_cTabMOv)->(dbCloseArea())

Return


/*/{Protheus.doc} CCK06RAT
Inclui rateio automatico
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
User Function CCK06RAT(_cNumMov)

	Local _nPos	 := At("-", ZCF->ZCF_DIDENT)
	Local _cConta:= ""
	Local _cTabIt:= ""
	Local _cItem := ""
	Local _cNaturez := ""

	If Alltrim(Substr(ZCF->ZCF_DIDENT,1,_nPos-1)) $"SECOR" .OR. Alltrim(ZCF->ZCF_DIDENT)=="DW3"
		If cEmpant == '03'	//RJ
			_cConta	:= "1160211"
		Else
			_cConta	:= "11502"		
		Endif
	ElseIf Alltrim(Substr(ZCF->ZCF_DIDENT,1,_nPos-1)) $"SPBA"
		If cEmpant == '03'	// RJ
			_cConta	:= "1160111"
		Else
			_cConta	:= "11501"		
		Endif
	Else
		_cConta	:= ""
	Endif

	If !Empty(_cConta)

		// Marca o titulo (adiantamento) como conta prestada e
		// o tira do fluxo de caixa.
		RecLock("ZCG",.F.)
		ZCG->ZCG_RATEIO  := "S"
		msUnLock()

		If Alltrim(ZCF->ZCF_RMU)=="R" //Privada
			_cNaturez	:= Iif(cEmpAnt=="03","1.01.01","01010101")
		ElseIf Alltrim(ZCF->ZCF_RMU)=="M" //Mista
			_cNaturez	:= Iif(cEmpAnt=="03","1.01.03","01010103")
		ElseIf Alltrim(ZCF->ZCF_RMU)=="U" //Publica
			_cNaturez	:= Iif(cEmpAnt=="03","1.01.02","01010102")
		Else
			_cNaturez	:= ""
		Endif

		_cTabIt := GetNextAlias()

		BeginSql Alias _cTabIt
		SELECT MAX(ZCH_ITEM) AS ITEM FROM %TABLE:ZCH% ZCH
		WHERE ZCH_FILIAL=%xfilial:ZCH%
			AND ZCH_BANCO = %Exp:ZCG->ZCG_BANCO% 
			AND ZCH_AGENCI = %Exp:ZCG->ZCG_AGENCI% 
			AND ZCH_REGIST = %Exp:ZCG->ZCG_REGIST%
			AND ZCH_RDR = %Exp:_cRDR%
			AND ZCH.D_E_L_E_T_=''	
		EndSql

		_cItem:= Iif(EMPTY((_cTabIt)->ITEM),"01",SOMA1((_cTabIt)->ITEM))

		(_cTabIt)->(dbCloseArea())

		RecLock("ZCH", .T.)
		ZCH->ZCH_FILIAL  	:= xFilial("ZCH")
		ZCH->ZCH_BANCO   	:= ZCG->ZCG_BANCO
		ZCH->ZCH_AGENCI 	:= ZCG->ZCG_AGENCI
		ZCH->ZCH_CONTA   	:= ZCG->ZCG_CONTA
		ZCH->ZCH_EMISSA 	:= ZCG->ZCG_EMISSA
		ZCH->ZCH_REGIST 	:= ZCG->ZCG_REGIST
		ZCH->ZCH_ITEM	  	:= _cItem
		ZCH->ZCH_VALOR	  	:= ZCF->ZCF_BA + ZCF->ZCF_CI
		ZCH->ZCH_CCONTA 	:= _cConta
		ZCH->ZCH_CR			:= ""
		ZCH->ZCH_NATURE	    := _cNaturez
		ZCH->ZCH_RMU		:= ZCF->ZCF_RMU
		ZCH->ZCH_TPSERV	    := ZCF->ZCF_TPSERV
		ZCH->ZCH_DC			:= "C"
		ZCH->ZCH_RDR     	:= ZCF->ZCF_RDR
		ZCH->ZCH_NUMMOV 	:= _cNumMov
		ZCH->(msUnLock())
	Endif

Return


/*/{Protheus.doc} CCK06DEV
Rotina de devolução do crédito
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function	 (Fora de Uso)
/*/
//Static Function CCK06DEV()

//Return


/*/{Protheus.doc} CCK06REC
Rotina de baixa do crédito como receita
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function	 (Fora de Uso)
/*/
//Static Function CCK06REC()

//Return


//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK06BXA
Rotina de baixa de créditos
@author  	Andy
@since     	28/04/03
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function CCK06DW3()

	Local oOk      := LoadBitmap( GetResources(), "LBOK" )
	Local oNo      := LoadBitmap( GetResources(), "LBNO" )
	Local cPerg    := PadR("CCADKDW3", Len(SX1->X1_GRUPO))
	Local cIdenDW3 := SuperGetMv("CI_IDENDW3",.F.,"96") //Identificação DW3

	aPags:= {}

	ValidPerg(cPerg)

	If Pergunte(cPerg, .T.)

		BeginSQL Alias "ZCGTMP"
			SELECT 
				ZCF_DTMOVI, ZCG_TIPO, ZCG_DEPOS, ZCG_VALOR, ZCG_NDOC, ZCG_NAGE, ZCF_IDENT, ZCG_BA, ZCG_CI, ZCG_RDR, ZCG_IR, ZCG_IRTIP, ZCG_IRRDR, ZCG.R_E_C_N_O_ REGZCG 
			FROM  %table:ZCG% ZCG
			INNER JOIN %table:ZCF% ZCF ON ZCF.%notDel% AND
				ZCF_FILIAL=%xFilial:ZCF% AND
				ZCF_REGIST=ZCG_REGIST AND
				ZCF_FECHAM<>'1' AND
				ZCF_IDENT=%Exp:cIdenDW3%  AND
				ZCF_DTMOVI BETWEEN %Exp:mv_par01%  AND %Exp:mv_par02%
			WHERE  ZCG.%notDel% 
				AND ZCG_FILIAL=%xFilial:ZCG% 
				AND ZCG_SALDO > 0
			GROUP BY
				ZCF_DTMOVI, ZCG_TIPO, ZCG_DEPOS, ZCG_VALOR, ZCG_NDOC, ZCG_NAGE, ZCF_IDENT, ZCG_BA, ZCG_CI, ZCG_RDR, ZCG_IR, ZCG_IRTIP, ZCG_IRRDR, ZCG.R_E_C_N_O_ 
			ORDER BY 
				ZCF_DTMOVI
		EndSQL

		While ZCGTMP->(!Eof())

			_cTipoDoc := LEFT(POSICIONE("SZ9",2,xFilial("SZ9")+ZCGTMP->ZCG_TIPO,"Z9_TIPO_D"),15)
			_cAgencia := POSICIONE("SZA",1,xFilial("SZA")+ZCGTMP->ZCG_NAGE,"ZA_NAGE_D")
			_cIdentif := LEFT(POSICIONE("SZB",1,xFilial("SZB")+ZCGTMP->ZCF_IDENT,"ZB_IDENT_D"),10)

			aAdd(aPags,{.F.,;
				StoD(ZCGTMP->ZCF_DTMOVI),;
				ZCGTMP->ZCG_TIPO+" - "+_cTipoDoc,;
				ZCGTMP->ZCG_DEPOS,;
				ZCGTMP->ZCG_VALOR,;
				ZCGTMP->ZCG_NDOC,;
				ZCGTMP->ZCG_NAGE,;
				_cAgencia,;
				ZCGTMP->ZCF_IDENT+" - "+_cIdentif,;
				ZCGTMP->ZCG_BA,;
				ZCGTMP->ZCG_CI,;
				ZCGTMP->ZCG_RDR,;
				ZCGTMP->ZCG_IR,;
				ZCGTMP->ZCG_IRTIP,;
				ZCGTMP->ZCG_IRRDR,;
				ZCGTMP->REGZCG})

			ZCGTMP->(dbSkip())
		Enddo
		ZCGTMP->(dbCloseArea())

		If Len(aPags) > 0

			DEFINE MSDIALOG oDlg FROM  31,58 To 300,778 TITLE "Escolha de qual movimento DW3 quer validar- " PIXEL
			@ 05,05 LISTBOX oLbx1 FIELDS HEADER "","Data","Tipo/Documento","Depositante","Valor","Documento","No.","Agencia","Identificacao","B.A.","C.I.","RDR","Irregularidade","Tipo Irreg.","RDR Irreg." SIZE 345, 85 OF oDlg PIXEL ;
				ON DBLCLICK ( CCK06M02() )

			oLbx1:SetArray(aPags)
			oLbx1:bLine := { || {Iif(aPags[oLbx1:nAt,1],oOk,oNo),aPags[oLbx1:nAt,2],aPags[oLbx1:nAt,3],aPags[oLbx1:nAt,4],Transform(aPags[oLbx1:nAt,5],"@EZ 999,999,999.99"),aPags[oLbx1:nAt,6],aPags[oLbx1:nAt,7],aPags[oLbx1:nAt,8],aPags[oLbx1:nAt,9],Transform(aPags[oLbx1:nAt,10],"@EZ 999,999,999.99"),Transform(aPags[oLbx1:nAt,11],"@EZ 999,999,999.99"),aPags[oLbx1:nAt,12],Transform(aPags[oLbx1:nAt,13],"@EZ 999,999,999.99"),aPags[oLbx1:nAt,14],aPags[oLbx1:nAt,15] } }
			oLbx1:nFreeze  := 1

			//@ 94, 010 BUTTON "Devolução de crédito" SIZE 60 ,12 ACTION ( Iif(CCK06DEV(),oDlg:End(),) ) Of oDlg PIXEL
			//@ 94, 090 BUTTON "Gerar Receita CIEE" SIZE 60 ,12 ACTION ( Iif(CCK06REC(),oDlg:End(),) ) Of oDlg PIXEL
			@ 94, 264 BUTTON "Marcar" SIZE 25 ,12 ACTION ( CCK06M03() ) Of oDlg PIXEL
			@ 94, 292 BUTTON "Editar" SIZE 25 ,12 ACTION ( Iif(CCK06RDR(1),oDlg:End(),) ) Of oDlg PIXEL
			@ 94, 320 BUTTON "Cancelar" SIZE 25 ,12 ACTION ( oDlg:End() ) Of oDlg PIXEL

			ACTIVATE MSDIALOG oDlg CENTERED
		Else
			MsgInfo("Não foram encontrados movimentos para validar!","Atenção")
		Endif
	Endif

Return


/*/{Protheus.doc} ValidPerg
//TODO Cria grupo de peruntas no SX1
@author marcelo.moraes
@since 05/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function ValidPerg(cPerg)

	Local aArea    := GetArea()
	Local aAreaSX1 := SX1->(GetArea())
	Local aRegs := {}
	Local i,j

	dbSelectArea("SX1")
	dbSetOrder(1)

	cPerg := PADR(cPerg,10)

	aAdd(aRegs,{cPerg,"01","Data Movimento de:   ","","","mv_ch1" ,"D",08,0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	aAdd(aRegs,{cPerg,"02","Data Movimento ate:  ","","","mv_ch2" ,"D",08,0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

	For i:=1 To Len(aRegs)
		If !dbSeek(cPerg+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 To FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Endif
	Next

	RestArea(aAreaSX1)
	RestArea(aArea)

Return()


/*/{Protheus.doc} ExistMovZCF
//TODO Verifica se o movimento ja existe na ZCF
@author marcelo.moraes
@since 05/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function ExistMovZCF(cRDR, cTipo, cNum, cPrefix, cParcel)

	Local lRet       := .F.
	Local aArea      := GetArea()
	Local _cAliasZCF := GetNextAlias()
	Local cQry	     := ""

	cQry := " SELECT "
	cQry += " ZCF_FILIAL "
	cQry += " FROM "+RetSqlName("ZCF")+" ZCF "
	cQry += " WHERE "
	cQry += " D_E_L_E_T_='' AND "
	cQry += " ZCF_FILIAL='"+xFilial("ZCF")+"' AND "
	cQry += " ZCF_RDR='"+alltrim(cRDR)+"' AND "
	cQry += " ZCF_TIPO='"+alltrim(cTipo)+"' AND "
	cQry += " ZCF_NUM='"+alltrim(cNum)+"' AND "
	cQry += " ZCF_PREFIX='"+alltrim(cPrefix)+"' AND "
	cQry += " ZCF_PARCEL='"+alltrim(cParcel)+"' "

	cQry := ChangeQuery(cQry)

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),_cAliasZCF,.T.,.T.)

	If (_cAliasZCF)->(!EOF())
		lRet := .T.
	Endif

	(_cAliasZCF)->(DbCloseArea())

	restarea(aArea)

Return(lRet)


//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK06TSR
Rotina de baixa Tesouraria
@author  	Mário Augusto Cavenaghi - EthosX
@since     	24/07/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function CCK06TSR()

	Local aCpos := {"ZCG_UNIDAD", "ZCG_RMU", "ZCG_TPSERV", "ZCG_CI", "ZCG_OBS"}

	Private cCadastro := "Baixa Tesouraria"

	M->ZCG_IDENT := Posicione("SZB", 3, xFilial("SZB") + __cUserID, "ZB_IDENT")
	If Empty(M->ZCG_IDENT)
		MsgInfo("Operador não cadastrado!", "Atenção")

	ElseIf ZCG->ZCG_SALDO > 0
		AxAltera("ZCG", ZCG->(Recno()), 4,, aCpos,,, "U_CCK06TOK()",, "U_CCK06INI()",,,,,,,, .T.,)

	Else
		MsgInfo("Crédito já baixado!", "Atenção")
	Endif

Return


//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK06TOK
Validação dos dados 
@author  	Mário Augusto Cavenaghi - EthosX
@since     	24/07/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function CCK06TOK()

	Local lRet := .T.

	If M->ZCG_CI <> ZCG->ZCG_SALDO
		MsgInfo("Não é permitido um valor diferente do SALDO!", "Favor Verificar")
		lRet := .F.
	Else
		M->ZCG_SALDO := 0
	Endif

Return(lRet)


//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK06INI
Inicialização de campos 
@author  	Mário Augusto Cavenaghi - EthosX
@since     	24/07/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function CCK06INI()

	M->ZCG_RDR    := SubStr(DtoS(Date()), 3, 6)
	M->ZCG_IDENT  := Posicione("SZB", 3, xFilial("SZB") + __cUserID   , "ZB_IDENT")
	M->ZCG_IDENTD := Posicione("SZB", 1, XFILIAL("SZB") + M->ZCG_IDENT, "ZB_IDENT_D")
	M->ZCG_DESAGE := Posicione("SZA", 1, XFILIAL("SZA") + M->ZCG_NAGE , "ZA_NAGE_D")

Return(.T.)
