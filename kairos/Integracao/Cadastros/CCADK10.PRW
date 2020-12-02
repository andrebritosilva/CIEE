#INCLUDE "rwmake.ch"
#DEFINE _EOL chr(13) + chr(10)
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCADK10
Rateio e Contabilizacao de CNI 
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CCADK10()
//Local _cVldAlt := ".T."   // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
//Local _cVldExc := ".T."   // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.
Private _cString := "ZCG", _bFiltraBrw, _aIndex := {}, _cFiltro
Private aRotina, cCadastro
Private _cAntCon :=space(10)
Private _cAntNat :=space(10)
Private _cAntRMU :=space(01)
Private _cAntTPS :=space(02)

ZCG->(dbSetOrder(2))

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Monta um aRotina proprio.                                  ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
aRotina := {;
  {"Pesquisar"      , "AxPesqui"       ,  0, 1},;
  {"Visualizar"     , "U_CCK10MAT(2)"  ,  0, 2},;
  {"Rateio"         , "U_CCK10MAT(6)"  ,  0, 4},;
  {"Cancelar Rateio", "U_CCK10MAT(7)"  ,  0, 5},;
  {"Relatorio"      , "U_CRELK02()"   ,  0, 6},;
  {"Alterar Rateio" , "U_CCK10MAT(4)"  ,  0, 7},;
  {"Legenda"        , "U_CCK10MAT(999)",  0, 8}}

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Exibe a tela de cadastro.                                  ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
cCadastro := "Cadastro de CNI"
mBrowse(06, 01, 22, 75, _cString,,,,,, CCK10LEG(0))

// Limpa o filtro do cadastro de contas a pagar.
Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณCCADK10   บAutor  ณ Felipe Raposo      บ Data ณ  12/03/03   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ CIEE.                                                      บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
User Function CCK10MAT(_nOpc)
// _nOpc
// 1 - Pesquisar
// 2 - Visual
// 3 - Incluir
// 4 - Alterar
// 5 - Excluir
// 6 - Legenda
// Os registros "ZCH" em SX3 com o campo X3_PROPRI=="L" sairใo no Acols
//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Declaracao de variaveis.                                            ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Local _lRet := .T., _aCpos, _cMsg, _aAreaZ8, _aAreaZCH
Local _aAux1, _nAux1, _nAux2, _aDel
Local _nTotPrest
Local _cTitulo, _cAlias1, _cAlias2, _aMyEncho, _cLinOk, _cTudoOk, _cValid
Local _nOpcE, _nOpcG, _cFieldOk, _cVirtual, _nLinhas, _aAltEnch
Local nCampos := 0
//Local _nCPMFAliq := 0.38  // Aliquota de CPMF. // Alteracao feita em 21/01/08 por Cristiano, conforme SSI 08/015
Private aCols, aHeader
Private _nItem := 1
Private _nOpcao := _nOpc
Private LVISUAL := (_nOpc == 2)
Private LINCLUI := (_nOpc == 3)
Private LALTERA := (_nOpc == 4)
Private LEXCLUI := (_nOpc == 5)

// Campos que serao exibidos na tela.
_aCpos := {"ZCG_BANCO", "ZCG_AGENCI", "ZCG_CONTA", "ZCG_EMISSA", "ZCG_CCONT", "ZCG_VALOR"}

// Armazena o posicionamento do alias SE2 antes de processa-lo.
_aAreaZ8 := ZCG->(GetArea())

Do Case
	Case _nOpc == 1  // Pesquisar
		//Nao faz nada.
		
	Case _nOpc == 2  // Visualizar.
		If Empty(ZCG_RATEIO)
			// Exibe o titulo adiantado.
			_lRet := (AxVisual(_cString, &(_cString)->(RecNo()), _nOpc, _aCpos) == 1)
		Else
			// Exibe o titulo com a prestacao de contas.
			_cTitulo  := "Rateio do CNI- Visualizar"
			_cAlias1  := _cString         // Alias da enchoice.
			_cAlias2  := "ZCH"            // Alias da GetDados.
			_aMyEncho := _aCpos           // Campos da Enchoice.
			_cFieldOk := "AllwaysTrue()"  // Valida cada campo da GetDados.
			_cLinOk   := "AllwaysTrue()"  // Valida a linha.
			_cTudoOk  := "AllwaysTrue()"  // Valida toda a GetDados.
			_nOpcE    := 2                // Opcao da Enchoice.
			_nOpcG    := 2                // Opcao da GetDados.
			_cVirtual := ".T."            // Exibe os campos virtuais na GetDados.
			_nLinhas  := 99               // Numero maximo de linhas na GetDados.
			_aAltEnch := nil              // Campos alteraveis na Enchoice (nil = todos).
			
			//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
			//ณ Cria variaveis M->????? da Enchoice.                         ณ
			//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
			RegToMemory(_cAlias1, .F.)
			
			// Monta a aHeader.
			aCampos := U_QualCPO( _cAlias2 )

			aHeader := {}
			For nCampos := 1 to Len( aCampos ) 
				If aCampos[ nCampos, 18] =="L"
					aAdd(aHeader, {	aCampos[ nCampos, 1] , ;
									aCampos[ nCampos, 2] , ;
									aCampos[ nCampos, 3] , ;
									aCampos[ nCampos, 4] , ;
									aCampos[ nCampos, 5] , ;
									"AllwaysTrue()"		 , ;
									aCampos[ nCampos, 7] , ;
									aCampos[ nCampos, 8] , ;
									_cAlias2, 			 , ;
									aCampos[ nCampos,10] , ;
									aCampos[ nCampos,12] })
				Endif
			Next
			
			// Monta a aCols com os itens do ZCH.
			aCols := {}
			_aAreaZCH := ZCH->(GetArea())
			ZCH->(dbSetOrder(1))  // ZCH_FILIAL+ZCH_NUM.
			ZCH->(dbSeek(xFilial("ZCH") + ZCG->ZCG_BANCO+ZCG->ZCG_AGENCI+ZCG->ZCG_CONTA+DTOS(ZCG->ZCG_EMISSA)+ZCG->ZCG_REGIST, .F.))  // +StrZero(ZCG->(RECNO()),15), .F.))
			Do While ZCH->(ZCH_FILIAL+ZCH_BANCO+ZCH_AGENCI+ZCH_CONTA+DTOS(ZCH_EMISSA)+ZCH_REGIST) == xFilial("ZCG")+ZCG->ZCG_BANCO+ZCG->ZCG_AGENCI+ZCG->ZCG_CONTA+DTOS(ZCG->ZCG_EMISSA)+ZCG->ZCG_REGIST //+StrZero(ZCG->(RECNO()),15), .F.))
			   
			    If ZCH->ZCH_RDR <> ZCG->ZCG_RDR
				   ZCH->(dbSkip())
				   Loop
                EndIf  

				_aAux1 := {}
				For _nAux1 := 1 to len( aHeader )
					If aHeader[ _nAux1, 10] == "V"
						aAdd(_aAux1, &(aHeader[ _nAux1, 11]))
					Else
						aAdd(_aAux1, ZCH->(&(aHeader[_nAux1, 2])))
					Endif
				Next _nAux1
				aAdd(_aAux1, .F.)
				aAdd(aCols, _aAux1)
				ZCH->(dbSkip())
			EndDo
			ZCH->(RestArea(_aAreaZCH))

			// Exibe a tela de modelo 3.
			_lRet := Modelo3(_cTitulo, _cAlias1, _cAlias2, _aMyEncho, _cLinOk, _cTudoOk,;
							_nOpcE, _nOpcG, _cFieldOk, &(_cVirtual), _nLinhas, _aAltEnch)
		Endif

	Case _nOpc == 4  // Alterar Rateio
			// Trata os erros.
		If Empty(ZCG_RDR)       // Fechado
			_cMsg := "Nใo houve informe de RDR nesse lan็amento "
			MsgAlert(_cMsg, "Aten็ใo")
			Return .F.
		Endif
		
/*		If Empty(ZCG_RATEIO)
			// Exibe o titulo adiantado.
			_lRet := (AxAltera(_cString, &(_cString)->(RecNo()), _nOpc, _aCpos) == 1)
		Else
*/
		If !Empty(ZCG_FECRAT)   // Fechado Rateio
			_cMsg := "Jแ houve FECHAMENTO DE RATEIO desse lan็amento "
			MsgAlert(_cMsg, "Aten็ใo")
			Return .F.
		Endif

		// Exibe o titulo com a prestacao de contas.
		_cTitulo  := "Rateio do CNI- Visualizar"
		_cAlias1  := _cString         // Alias da enchoice.
		_cAlias2  := "ZCH"            // Alias da GetDados.
		_aMyEncho := _aCpos           // Campos da Enchoice.

		_cFieldOk := "U_CCK10VLD(1)"  // Valida cada campo da GetDados.
		_cLinOk   := "U_CCK10VLD(2)"  // Valida a linha.
		_cTudoOk  := "U_CCK10VLD(3)"  // Valida toda a GetDados.
		_nOpcE    := 2                // Opcao da Enchoice.
		_nOpcG    := 3                // Opcao da GetDados.
		_cVirtual := ".T."            // Exibe os campos virtuais na GetDados.
		_nLinhas  := 99               // Numero maximo de linhas na GetDados.
		_aAltEnch := nil              // Campos alteraveis na Enchoice (nil = todos).
		
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ Cria variaveis M->????? da Enchoice.                         ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		RegToMemory(_cAlias1, .F.)
		
		// Monta a aHeader.
		aHeader := {}

		aCampos := U_QualCPO( _cAlias2 )

		For nCampos := 1 to Len( aCampos )
			If aCampos[ nCampos ,18 ] == "L"
				aAdd(aHeader, {	aCampos[ nCampos , 1 ],  ;
								aCampos[ nCampos , 2 ],  ; 
								aCampos[ nCampos , 3 ],  ;
								aCampos[ nCampos , 4 ],  ;
								aCampos[ nCampos , 5 ],  ; 
								"AllwaysTrue()"		  ,  ;
								aCampos[ nCampos , 7 ],  ;
								aCampos[ nCampos , 8 ],  ;
								_cAlias2			  ,  ; 
								aCampos[ nCampos ,10 ],  ; 
								aCampos[ nCampos ,12 ] })
			Endif
		End
		
		// Monta a aCols com os itens do ZCH.
		aCols := {}
		_aAreaZCH := ZCH->(GetArea())
		DbSelectArea("ZCH")
		ZCH->(dbSetOrder(1))  // ZCH_FILIAL+ZCH_NUM.
		ZCH->(dbSeek(xFilial("ZCH") + ZCG->ZCG_BANCO+ZCG->ZCG_AGENCI+ZCG->ZCG_CONTA+DTOS(ZCG->ZCG_EMISSA)+ZCG->ZCG_REGIST, .F.))  // +StrZero(ZCG->(RECNO()),15), .F.))
		Do While ZCH->(ZCH_FILIAL+ZCH_BANCO+ZCH_AGENCI+ZCH_CONTA+DTOS(ZCH_EMISSA)+ZCH_REGIST) == xFilial("ZCG")+ZCG->ZCG_BANCO+ZCG->ZCG_AGENCI+ZCG->ZCG_CONTA+DTOS(ZCG->ZCG_EMISSA)+ZCG->ZCG_REGIST //+StrZero(ZCG->(RECNO()),15), .F.))
		   
		    If ZCH->ZCH_RDR == ZCG->ZCG_RDR
				_aAux1 := {}
				For _nAux1 := 1 to len(aHeader)
					If aHeader[_nAux1,10] == "V"
						aAdd(_aAux1, &(aHeader[_nAux1,11]))
					Else
						aAdd(_aAux1, ZCH->(&(aHeader[_nAux1, 2])))
					Endif
				Next _nAux1
				aAdd(_aAux1, .F.)
				aAdd(aCols, _aAux1)
			Endif
			ZCH->(dbSkip())
		EndDo
		ZCH->(RestArea(_aAreaZCH))
		
		// Exibe a tela de modelo 3.
		_lRet := Modelo3(_cTitulo, _cAlias1, _cAlias2, _aMyEncho, _cLinOk, _cTudoOk,;
						_nOpcE, _nOpcG, _cFieldOk, &(_cVirtual), _nLinhas, _aAltEnch)
		If _lRet  // Usuario confirmou a operacao.
			Begin Transaction
			ZCH->(dbSetOrder(1))
			ZCH->(dbSeek(xFilial("ZCH") + ZCG->ZCG_BANCO+ZCG->ZCG_AGENCI+ZCG->ZCG_CONTA+DTOS(ZCG->ZCG_EMISSA)+ZCG->ZCG_REGIST, .F.))
			// Grava os itens da prestacao de contas (ZCH).
			_nTotPrest := 0
			For _nAux1 := 1 to len(aCols)
				// Varre todos os itens.
				ZCH->(dbSetOrder(4))
				If ZCH->(dbSeek(xFilial("ZCH") + ZCG->ZCG_BANCO+ZCG->ZCG_AGENCI+ZCG->ZCG_CONTA+DTOS(ZCG->ZCG_EMISSA)+ZCG->ZCG_REGIST+aCols[_nAux1,2], .F.))
					If !aCols[_nAux1, len(aHeader) + 1]
						RecLock("ZCH", .F.)
						ZCH->ZCH_FILIAL  := xFilial("ZCH")
						ZCH->ZCH_BANCO   := ZCG->ZCG_BANCO
						ZCH->ZCH_AGENCI := ZCG->ZCG_AGENCI
						ZCH->ZCH_CONTA   := ZCG->ZCG_CONTA
						ZCH->ZCH_EMISSA := ZCG->ZCG_EMISSA
						ZCH->ZCH_REGIST := ZCG->ZCG_REGIST
						ZCH->ZCH_RDR     := ZCG->ZCG_RDR
						For _nAux2 := 1 to len(aHeader)
							ZCH->(&(aHeader[_nAux2, 2])) := aCols[_nAux1, _nAux2]
						Next _nAux2
						ZCH->(msUnLock())
						_cAntCon :=aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_CCONTA"})]
						_cAntNat :=aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_NATURE"})]
						_cAntRMU :=aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_RMU"})]
						_cAntTPS :=aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_TPSERV"})]
					Else
						RecLock("ZCH", .F.)
						ZCH->(dbDelete())
						ZCH->(msUnLock())
					Endif
				Else
					If !aCols[_nAux1, len(aHeader) + 1]
						RecLock("ZCH", .T.)
						ZCH->ZCH_FILIAL  := xFilial("ZCH")
						ZCH->ZCH_BANCO   := ZCG->ZCG_BANCO
						ZCH->ZCH_AGENCI := ZCG->ZCG_AGENCI
						ZCH->ZCH_CONTA   := ZCG->ZCG_CONTA
						ZCH->ZCH_EMISSA := ZCG->ZCG_EMISSA
						ZCH->ZCH_REGIST := ZCG->ZCG_REGIST
						ZCH->ZCH_RDR     := ZCG->ZCG_RDR
						For _nAux2 := 1 to len(aHeader)
							ZCH->(&(aHeader[_nAux2, 2])) := aCols[_nAux1, _nAux2]
						Next _nAux2
						ZCH->(msUnLock())
						_cAntCon :=aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_CCONTA"})]
						_cAntNat :=aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_NATURE"})]
						_cAntRMU :=aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_RMU"})]
						_cAntTPS :=aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_TPSERV"})]
					Endif
				EndIf
			Next _nAux1
		
			End Transaction
		Endif
				
	Case _nOpc == 6  // Prestar conta.
		
		// Trata os erros.
		If Empty(ZCG_RDR)       // Fechado
			_cMsg := "Nใo houve informe de RDR nesse lan็amento "
			MsgAlert(_cMsg, "Aten็ใo")
			Return .F.
		Endif
		
		If !Empty(ZCG_RATEIO)   // Baixado
			_cMsg := "Jแ houve RATEIO desse lan็amento "
			MsgAlert(_cMsg, "Aten็ใo")
			Return .F.
		Endif
      
		If Empty(ZCG_FECHA)   // Nใo Fechado CNI
			_cMsg := "NรO FECHAMENTO CNI desse lan็amento "
			MsgAlert(_cMsg, "Aten็ใo")
			Return .F.
		Endif
		
		If !Empty(ZCG_FECRAT)   // Fechado Rateio
			_cMsg := "Jแ houve FECHAMENTO DE RATEIO desse lan็amento "
			MsgAlert(_cMsg, "Aten็ใo")
			Return .F.
		Endif
		
		_cTitulo  := "Rateio - CNI"
		_cAlias1  := _cString         // Alias da enchoice.
		_cAlias2  := "ZCH"            // Alias da GetDados.
		_aMyEncho := _aCpos           // Campos da Enchoice.
		_cFieldOk := "U_CCK10VLD(1)"  // Valida cada campo da GetDados.
		_cLinOk   := "U_CCK10VLD(2)"  // Valida a linha.
		_cTudoOk  := "U_CCK10VLD(3)"  // Valida toda a GetDados.
		_nOpcE    := 2                // Opcao da Enchoice.
		_nOpcG    := 3                // Opcao da GetDados.
		_cVirtual := ".T."            // Exibe os campos virtuais na GetDados.
		_nLinhas  := 99               // Numero maximo de linhas na GetDados.
		_aAltEnch := nil              // Campos alteraveis na Enchoice (nil = todos).
		
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ Cria variaveis M->????? da Enchoice.                         ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		RegToMemory(_cAlias1, .F.)
		
		// Monta a aHeader.
		aHeader := {}
		aCampos := U_QualCPO( _cAlias2 )
		For nCampos := 1 to Len( aCampos )
			If aCampos[ nCampos, 18 ] == "L"
				_cValid := IIf (!empty(aCampos[ nCampos, 6 ]), aCampos[ nCampos, 6 ], "")
				_cValid += IIf (!empty(_cValid) .and. !empty(aCampos[ nCampos, 15 ]), ".and." , "")
				_cValid += IIf (!empty(aCampos[ nCampos, 15 ]), aCampos[ nCampos, 15 ], "")
				_cValid := IIf (empty(_cValid), "AllwaysTrue()", _cValid)
				
				aAdd(aHeader, {	aCampos[ nCampos, 1 ], ;
								aCampos[ nCampos, 2 ], ; 
								aCampos[ nCampos, 3 ], ;
								aCampos[ nCampos, 4 ], ; 
								aCampos[ nCampos, 5 ], ;
								_cValid				 , ;
								aCampos[ nCampos, 7 ], ;
								aCampos[ nCampos, 8 ], ;
								_cAlias2			 , ;
								aCampos[ nCampos, 10], ;
								aCampos[ nCampos, 12] })
			Endif
		Next

		// Monta a aCols em branco.
		aCols := {Array(len(aHeader) + 1)}
		For _nAux1 := 1 to len(aHeader)
			aCols[1, _nAux1] :=;
			iif(!Empty(_nAux1,aHeader[_nAux1, 11]), &(aHeader[_nAux1, 11]), CriaVar(aHeader[_nAux1, 2]))
		Next _nAux1
		
		aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_ITEM"		})]	:= "01"
		aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_VALOR"	})]	:= ZCG->ZCG_VALOR
		aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_CCONTA"	})]	:= _cAntCon
		aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_NATURE"	})]	:= _cAntNat
		aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_RMU"		})]	:= _cAntRMU				
		aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_TPSERV"	})]	:= _cAntTPS
		aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_ITEMD"	})]	:= Space( FwTamSX3("ZCH_ITEMD")[1])
		aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_COMPET"	})]	:= Space( FwTamSX3("ZCH_COMPET")[1])

		aCols[1, len(aHeader) + 1] := .F.
		
		// Exibe a tela de modelo 3.
		_lRet := Modelo3(_cTitulo, _cAlias1, _cAlias2, _aMyEncho, _cLinOk, _cTudoOk,;
						_nOpcE, _nOpcG, _cFieldOk, &(_cVirtual), _nLinhas, _aAltEnch)
		If _lRet  // Usuario confirmou a operacao.
			Begin Transaction
			
			// Marca o titulo (adiantamento) como conta prestada e
			// o tira do fluxo de caixa.
			RecLock("ZCG", .F.)
			ZCG->ZCG_RATEIO  := "S"
			ZCG->(msUnLock())
			
			// Grava os itens da prestacao de contas (ZCH).
			_nTotPrest := 0
			For _nAux1 := 1 to len(aCols)
				// Varre todos os itens.
				If !aCols[_nAux1, len(aHeader) + 1]
					RecLock("ZCH", .T.)
					ZCH->ZCH_FILIAL  := xFilial("ZCH")
					ZCH->ZCH_BANCO   := ZCG->ZCG_BANCO
					ZCH->ZCH_AGENCI := ZCG->ZCG_AGENCI
					ZCH->ZCH_CONTA   := ZCG->ZCG_CONTA
					ZCH->ZCH_EMISSA := ZCG->ZCG_EMISSA
					ZCH->ZCH_REGIST := ZCG->ZCG_REGIST // StrZero(ZCG->(RECNO()),15)
					ZCH->ZCH_RDR     := ZCG->ZCG_RDR
					
					For _nAux2 := 1 to len(aHeader)
						ZCH->(&(aHeader[_nAux2, 2])) := aCols[_nAux1, _nAux2]
					Next _nAux2
					
					ZCH->(msUnLock())
					_cAntCon :=aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_CCONTA" })]
					_cAntNat :=aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_NATURE"})]
					_cAntRMU :=aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_RMU"	 })]
					_cAntTPS :=aCols[1, aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_TPSERV" })]										
				Endif
			Next _nAux1
			
			
			End Transaction
		Endif
		
	Case _nOpc == 7  // Cancelar prestacao.
		
		// Trata os erros.
		If Empty(ZCG->ZCG_RATEIO)   // Baixado
			_cMsg := "Nใo houve  RATEIO  desse lan็amento para ser cancelado!"
			MsgAlert(_cMsg, "Aten็ใo")
			Return .F.
		Endif
		
		If !Empty(ZCG->ZCG_FECRAT)   // Fechado
			_cMsg := "Jแ houve FECHAMENTO desse lan็amento para ser cancelado!"
			MsgAlert(_cMsg, "Aten็ใo")
			Return .F.
		Endif
		
		
		_lRet := U_CCK10MAT(2)
		If _lRet  // Usuario confirmou a operacao.
			Begin Transaction
			
			// Desmarca o titulo (adiantamento) como conta prestada e
			// o coloca de volta no fluxo de caixa.
			RecLock("ZCG", .F.)
			ZCG->ZCG_RATEIO := " "
			ZCG->(msUnLock())
			
			// Apaga os itens da prestacao de contas (SZ4).
			_aDel := {}
			ZCH->(dbSetOrder(1))
			ZCH->(dbSeek(xFilial("ZCH") + ZCG->ZCG_BANCO+ZCG->ZCG_AGENCI+ZCG->ZCG_CONTA+DTOS(ZCG->ZCG_EMISSA)+ZCG->ZCG_REGIST), .F.) //+StrZero(ZCG->(RECNO()),15), .F.))
			Do While ZCH->(ZCH_FILIAL+ZCH_BANCO+ZCH_AGENCI+ZCH_CONTA+DTOS(ZCH_EMISSA)+ZCH_REGIST) == xFilial("SZ4")+ZCG->ZCG_BANCO+ZCG->ZCG_AGENCI+ZCG->ZCG_CONTA+DTOS(ZCG->ZCG_EMISSA)+ZCG->ZCG_REGIST // +StrZero(ZCG->(RECNO()),15)
				aAdd(_aDel, ZCH->(RecNo()))
				ZCH->(dbSkip())
			EndDo
			
			For _nAux1 := 1 to len(_aDel)
				ZCH->(dbGoTo(_aDel[_nAux1]))
				RecLock("ZCH", .F.)
				ZCH->(dbDelete())
				ZCH->(msUnLock())
			Next _nAux1
			
			
			End Transaction
		Endif
		
	Case _nOpc == 999  // Legenda.
		CCK10LEG()
		
	OtherWise
EndCase

// Retorna o posicionamento do alias SE2.
ZCG->(RestArea(_aAreaZ8))
Return(_lRet)


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณCCK10VLD  บAutor  ณMicrosiga           บ Data ณ  03/17/03   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Valida a digitacao do usuario na GetDados.                 บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณ _nOpc:                                                     บฑฑ
ฑฑบ          ณ 1 - Para validar cada campo.                               บฑฑ
ฑฑบ          ณ 2 - Para validar a linha.                                  บฑฑ
ฑฑบ          ณ 3 - Para validar a aCols inteira.                          บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณ .T. - Validacao ok.                                        บฑฑ
ฑฑบesperado  ณ .F. - Nao validado.                                        บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP6                                                        บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
User Function CCK10VLD(_nOpc)

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Declaracao de variaveis.                                            ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Local _lRet := .F.
Local _nAux1
Local _nPsItem  := aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_ITEM"  })
Local _nPsConta := aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_CCONTA"})
//Local _nPsCusto := aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_CCUSTO"})
Local _nPsValor := aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_VALOR" })
Local _nPsDC    := aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_DC"    })

Local _nPsCompet:= aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_COMPET"})
Local _nPsNature:= aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_NATURE"})

Do Case
	Case _nOpc == 1  // Valida o campo.
		_lRet := .T.
	Case _nOpc == 2  // Valida a linha.
		If (_lRet := aCols[n, len(aHeader) + 1] .or. !( Empty(aCols[n, _nPsConta]) .or. Empty(aCols[n, _nPsValor])))
			_nItem := val(aCols[len(aCols), _nPsItem]) + 1
		Else
			_cMsg := "Preencha todos os campos!"
			MsgAlert(_cMsg, "Aten็ใo")
		Endif

		//If (cEmpAnt=="01" .And. Substr(alltrim(aCols[n, _nPsNature]),1,4) $ "0401|0402") .Or. (cEmpAnt<>"01" .And. Substr(alltrim(aCols[n, _nPsNature]),1,4) $ "6.10|6.11")
		If (cEmpAnt=="03" .And. Substr(alltrim(aCols[n, _nPsNature]),1,4) $ "6.10|6.11") .Or. (cEmpAnt<>"03" .And. Substr(alltrim(aCols[n, _nPsNature]),1,4) $ "0401|0402")
		
			If Empty(aCols[n, _nPsCompet]) .or. aCols[n, _nPsCompet] == "  /    "
				_cMsg := "Preencha campo Competencia!"
				MsgAlert(_cMsg, "Aten็ใo")
				_lRet := .F.
			EndIf
				//Patricia Fontanezi	06/09/2012
	        IF !EMPTY(aCols[n, _nPsCompet])
				IF VAL(SUBSTR(aCols[n, _nPsCompet],1,2)) < 01 .OR. VAL(SUBSTR(aCols[n, _nPsCompet],1,2)) > 12
					MSGINFO("M๊s Incorreto. Digite novamente !") 
					_lRet	:= .F.
				ELSE
					If VAL(SUBSTR(aCols[n, _nPsCompet],4,4)) < 2012 .OR. VAL(SUBSTR(aCols[n, _nPsCompet],4,4)) > 2100
						MSGINFO("Ano Incorreto. Figite novamente !")
						_lRet	:= .F.
					Endif
				ENDIF  
			Endif				
		EndIf              
	

	Case _nOpc == 3  // Valida a aCols.
		If (_lRet := U_CCK10VLD(2))
			// Conta o total dos itens da prestacao de contas.
			_nTotal := 0
			For _nAux1 := 1 to len(aCols)
				If !aCols[_nAux1, len(aHeader) + 1]
					If aCols[_nAux1, _nPsDC] == "D"
						_nTotal -= aCols[_nAux1, _nPsValor]
					Else
						_nTotal += aCols[_nAux1, _nPsValor]
					EndIf
				Endif
			Next _nAux1
			
			If M->ZCG_VALOR <> _nTotal
				_cMsg := "O valor total do rateio (" +;
				AllTrim(Transform(_nTotal, tm(_nTotal, 14))) +;
				") nใo bate com o valor do cr้dito (" +;
				AllTrim(Transform(M->ZCG_VALOR, tm(M->ZCG_VALOR, 14))) + ")." + _EOL
				_lRet := .F.
				MsgAlert(_cMsg, "Aten็ใo")
			Endif
		EndIf
EndCase

Return(_lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณLegenda   บAutor  ณ Andy               บ Data ณ  12/01/04   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Exibe a legenda ou retorna a matriz referente a legenda    บฑฑ
ฑฑบ          ณ para a mBrowse.                                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณ _uPar:                                                     บฑฑ
ฑฑบ          ณ      0 - Retorna a matriz.                                 บฑฑ
ฑฑบ          ณ    nil - Exibe a legenda na tela.                          บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP6                                                        บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function CCK10LEG(_uPar)

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Declaracao de variaveis.                                            ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Local _uRet, _aFlag

_aLeg := {;
{"BR_VERDE"   ,  "Sem Rateio"},;
{"BR_AMARELO" ,  "Com Rateio"},;
{"BR_VERMELHO",  "Com Rateio  e Fechamento"}}

If ValType(_uPar) != "U" .and. _uPar == 0
	_aFlag := {;
	{'!Empty(ZCG_FECRAT)', _aLeg[3][1]},;  // Vermelho.
	{'!Empty(ZCG_RATEIO)', _aLeg[2][1]},;  // Amarelo.
	{' Empty(ZCG_RATEIO)', _aLeg[1][1]}}   // Verde.
	_uRet := _aFlag
Else
	BrwLegenda(cCadastro, "Legenda", _aLeg)
Endif
Return (_uRet)

/*/{Protheus.doc} CCK10CPT
Validacao na digitacao de meses e ano no campo ZCH_COMPET
@author Patricia Fontanezi
@since 06/09/12
@version undefined
@type function
/*/
User function CCK10CPT(nTipo)
Local _cRet		:= .T.  
Local _aArea	:= GetArea()   
Local _cNature	:= aScan(aHeader, {|x| AllTrim(x[2]) == "ZCH_NATURE"})

IF !EMPTY(M->ZCH_COMPET) .AND. !EMPTY(aCols[n][_cNature])
	If Substr(alltrim(aCols[n][_cNature]),1,4) $ "0401|0402" .or. Substr(alltrim(aCols[n][_cNature]),1,4) $ "6.10|6.11"
		IF VAL(SUBSTR(M->ZF_XCOMPET,1,2)) < 01 .OR. VAL(SUBSTR(M->ZF_XCOMPET,1,2)) > 12
			MSGINFO("M๊s Incorreto. Digite novamente !") 
			_cRet	:= .F.
		ELSE
			If VAL(SUBSTR(M->ZF_XCOMPET,4,4)) < 2012 .OR. VAL(SUBSTR(M->ZF_XCOMPET,4,4)) > 2100
				MSGINFO("Ano Incorreto. Digite novamente !")
				_cRet	:= .F.
			Endif
		ENDIF   
	Endif 
Endif

RestArea(_aArea)

RETURN(_cRet)    
