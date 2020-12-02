#INCLUDE "Protheus.ch"
#INCLUDE "rwmake.ch"

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CFINA20
Conciliacao do Movimento Bancario
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function CFINA20()
	Local cArq,cInd,cPerg
	Local cString := "SE5"
	Local aStru
	Local cVldAlt := ".T." // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
	Local cVldExc := ".T." // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.
	Private aPags := {}
	Private _dPar01, _dPar02
	Private _cSZ8Ban, _cSZ8Age, _cSZ8Con, _dSZ8Emi, _dSZ8Tip
	Private _lRet
	Private _lClose := .F.
	
	_cSZ8Ban:=Space(03)
	_cSZ8Age:=Space(05)
	_cSZ8Con:=Space(10)
	_cSZ8Tip:=Space(02)
	_dSZ8Emi:=dDataBase
	_cSZ8Cta:=Space(10)
	dbSelectArea("SE5")
	dbSetOrder(1)
	
	// AxInclui(cAlias,nReg,nOpc,aAcho,cFunc,aCpos,cTudoOk,lF3)
	// AxAltera(cAlias,nReg,nOpc,aAcho,aCpos,nColMens,cMensagem,cTudoOk)
	// AxDeleta(cAlias,nReg,nOpc,aAcho,cFunc)
	
	
	cCadastro := "Conciliacao Contas a Pagar - Movimentacao Bancaria"
	aCores    := {}
	aRotina   := { 	{"Pesquisar" ,"AxPesqui"    , 0 , 1},;
		{"Visualizar"   ,"AxVisual"   , 0 , 2},;
		{"Conciliar"    ,"U_C6A20CON" , 0 , 3},;
		{"Extrato"      ,"U_CFINR09"   , 0 , 4},;
		{"Legenda"      ,'BrwLegenda(cCadastro,"Legenda",{{"BR_VERDE","Nao Conciliado"},{"BR_VERMELHO","Conciliado"},{"BR_AZUL","Cancelado"}})',0 , 5 }}
	
	Aadd( aCores, { "  Empty(E5_RECONC) .And. E5_SITUACA = ' '                         "  , "BR_VERDE" 	} )
	Aadd( aCores, { " !Empty(E5_RECONC) .And. E5_SITUACA = ' '                         "  , "BR_VERMELHO"	} )
	Aadd( aCores, { " (Empty(E5_RECONC) .Or. Empty(E5_RECONC)) .And. E5_SITUACA <> ' ' "  , "BR_AZUL"	} )
	
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณRealiza a Filtragem                                                     ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	
	dbSelectArea("SE5")
	dbSetOrder(1)
	
	mBrowse( 6,1,22,75,"SE5",,,,,2, aCores)
	
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ C6A20CON บ Autor ณ Andy               บ Data ณ  28/04/03   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Preenche Z8_RDR ou Z8_RDRIR, no Programa CFINA11           บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/

User Function C6A20CON()
	Local _nI	   := 0
	Private cPerg  := "CFINA20"
	
	If .not. U_TemSX1( cPerg )
		Return
	Endif
	If !Pergunte(cPerg, .T.)
		Return
	EndIf
	
	While .T.
		C6A20TE5()
		If !_lRet
			Exit
		EndIf
	EndDo
Return

static Function C6A20TE5()
	
	Local aArea    := GetArea() //, aPags := {}
	Local oOk      := LoadBitmap( GetResources(), "LBOK" )
	Local oNo      := LoadBitmap( GetResources(), "LBNO" )
	Local _nI	   := 0
	aPags          := {}
	
	dbSelectArea("SA6")
	dbSetOrder(1)
	IF !(dbSeek(cFilial+mv_par01+mv_par02+mv_par03))
		Help(" ",1,"BCONAOEXIST")
		Return
	EndIF
	
	_cBanco	:= A6_COD
	_cAgencia	:= A6_AGENCIA
	_cConta	:= A6_NUMCON
	
	DbSelectArea("SE5")
	DbSetOrder(1)
	cChave  := "E5_FILIAL+DTOS(E5_DTDISPO)+E5_BANCO+E5_AGENCIA+E5_CONTA+E5_DOCUMEN+E5_NUMCHEQ"
	
	cOrder := SqlOrder(cChave)
	cQuery := "SELECT *, "+ RetSqlName("SE5") +".R_E_C_N_O_ REGSE5 "
	cQuery += " FROM " + RetSqlName("SE5") + " WHERE "
	cQuery += "	E5_FILIAL = '" + xFilial("SE5") + "'" + " AND "
	cQuery += " D_E_L_E_T_ <> '*' "
	cQuery += " AND E5_DTDISPO >=  '"     + DTOS(mv_par04) + "'"
	cQuery += " AND E5_DTDISPO <=  '"     + DTOS(mv_par05) + "'"
	cQuery += " AND E5_BANCO = '"   + _cBanco   + "'"
	cQuery += " AND E5_AGENCIA = '" + _cAgencia + "'"
	cQuery += " AND E5_CONTA = '"   + _cConta   + "'"
	cQuery += " AND E5_SITUACA = ' ' "
	cQuery += " AND E5_VALOR <> 0 "
	cQuery += " AND E5_NUMCHEQ NOT LIKE '%*' "
	cQuery += " AND E5_VENCTO <= '" + DTOS(mv_par05)  + "'"
	cQuery += " AND E5_VENCTO <= E5_DATA "
	cQuery += " AND E5_RECONC = ' ' "
	cQuery += " AND ( (E5_TIPODOC IN ('VL','CH','BA')) OR  " // AND E5_MOEDA IN ('01') ALTERADO MOEDA DE BRANCO PARA 01
	cQuery += "       (E5_TIPODOC IN ('  ')      AND E5_MOEDA IN ('TB','BA','FL','AP','CD','ES','GE','DD','RG','NI','RS','DE')) OR  "
	cQuery += "       (E5_TIPODOC IN ('BA')      AND E5_TIPO  IN ('FL ')                                            ) OR  "
	cQuery += "       (E5_TIPODOC IN ('PA')      AND E5_TIPO  IN ('PA ')                                            ) OR  "	//EXCLUSIVO 
	cQuery += "       (E5_TIPODOC IN ('TR') AND E5_MOEDA IN ('TR','TE')                                                  ))    "
	cQuery += " AND E5_PREFIXO NOT IN ('SEC','SBA','FCB')"
	cQuery += " ORDER BY " + cOrder
	cQuery := ChangeQuery(cQuery)
	
	dbSelectAre("SE5")
	
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'SE5TMP', .T., .T.)
	
	dbSelectArea("SE5TMP")
	dbGoTop()
	
	_nConta      := 1
	
	While !Eof()
		
		_dE5_DTDISPO := SE5TMP->E5_DTDISPO
		_cE5_DOCUMEN := SE5TMP->E5_DOCUMEN
		_cE5_NUMCHEQ := SE5TMP->E5_NUMCHEQ
		_nTotal      := 0
		_cE5_NUMERO  := SE5TMP->E5_NUMERO
		
		While !Eof() .And. _cE5_DOCUMEN == SE5TMP->E5_DOCUMEN .And. _cE5_NUMCHEQ == SE5TMP->E5_NUMCHEQ //.AND. _cE5_NUMERO == SE5TMP->E5_NUMERO
			
			_cOpera:=" "
			
			If SE5TMP->E5_MOEDA $ "BA;TB;FL;AP;CD;TR;ES;GE;DD;RG;NI;RS;DE;TE" .Or. (SE5TMP->E5_TIPODOC =='BA' .And. SE5TMP->E5_TIPO =='FL ' )
				Do Case
				Case SE5TMP->E5_MOEDA $ "BA" ; _cOpera := "Pagamento Bolsa Auxilio"
				Case SE5TMP->E5_MOEDA $ "TB" ; _cOpera := "Despesa Bancaria"
				Case SE5TMP->E5_MOEDA $ "TR" ; _cOpera := "Transferencia"
				Case SE5TMP->E5_MOEDA $ "TE" ; _cOpera := "Transferencia"
				OtherWise
					_cOpera := AllTrim(SE5TMP->E5_BENEF)
				EndCase
			Else
				If !EMPTY(SE5TMP->E5_DOCUMEN)
					_cOpera := "Bordero para pgto."
				ElseIf !EMPTY(SE5TMP->E5_NUMCHEQ)
					_cOpera := AllTrim(SE5TMP->E5_BENEF)
				EndIf
			EndIf
			
			If Empty(_cOpera) .And.  SE5TMP->E5_TIPO = "PBA"
				_cOpera := "Pagamento Bolsa Auxilio"
			EndIf
			
			_cOpera := SubStr(_cOpera,1,23)
			
			_cDocumento := " "
			
			If SE5TMP->E5_TIPO = "PBA"
				_cDocumento := Alltrim(SE5TMP->E5_NUMERO)
			EndIf
			
			If SE5TMP->E5_MOEDA $ "BA;TB;FL;AP;CD;TR;ES;GE;DD;RG;NI;RS;DE;TE"  .Or. (SE5TMP->E5_TIPODOC =='BA' .And. SE5TMP->E5_TIPO =='FL ' )
				
				Do Case
				Case SE5TMP->E5_MOEDA $ "BA" ; _cDocumento := "BA "+AllTrim(SE5TMP->E5_DOCUMEN)
				Case SE5TMP->E5_MOEDA $ "TB" ; _cDocumento := "Tarifa"
				Case SE5TMP->E5_MOEDA $ "TR" ; _cDocumento := "TB "+IIF(Empty(AllTrim(SE5TMP->E5_DOCUMEN)),Alltrim(SE5TMP->E5_NUMCHEQ),AllTrim(SE5TMP->E5_DOCUMEN))
				Case SE5TMP->E5_MOEDA $ "TE" ; _cDocumento := "TB "+IIF(Empty(AllTrim(SE5TMP->E5_DOCUMEN)),Alltrim(SE5TMP->E5_NUMCHEQ),AllTrim(SE5TMP->E5_DOCUMEN))
				Case SE5TMP->E5_MOEDA $ "FL" ; _cDocumento := "FL "+AllTrim(SE5TMP->E5_DOCUMEN)
				Case SE5TMP->E5_MOEDA $ "AP" ; _cDocumento := "AP "+AllTrim(SE5TMP->E5_DOCUMEN)
				Case SE5TMP->E5_MOEDA $ "CD" ; _cDocumento := "CD "+AllTrim(SE5TMP->E5_DOCUMEN)
				Case SE5TMP->E5_MOEDA $ "ES" ; _cDocumento := "ES "+AllTrim(SE5TMP->E5_DOCUMEN)
				Case SE5TMP->E5_MOEDA $ "GE" ; _cDocumento := "GE "+AllTrim(SE5TMP->E5_DOCUMEN)
				Case SE5TMP->E5_MOEDA $ "NI" ; _cDocumento := "NI "+AllTrim(SE5TMP->E5_DOCUMEN)
				Case SE5TMP->E5_MOEDA $ "DD" ; _cDocumento := "DD "+AllTrim(SE5TMP->E5_DOCUMEN)
				Case SE5TMP->E5_MOEDA $ "RG" ; _cDocumento := "RG "+AllTrim(SE5TMP->E5_DOCUMEN)
				Case SE5TMP->E5_MOEDA $ "RS" ; _cDocumento := "RS "+AllTrim(SE5TMP->E5_DOCUMEN)
				Case SE5TMP->E5_MOEDA $ "DE" ; _cDocumento := "DE "+AllTrim(SE5TMP->E5_DOCUMEN)
				Case SE5TMP->E5_TIPO == "FL "; _cDocumento := "FL "+AllTrim(SE5TMP->E5_NUMERO)
					
				OtherWise
					_cDocumento := AllTrim(SE5TMP->E5_DOCUMEN)
					
				EndCase
			Else
				If !EMPTY(SE5TMP->E5_DOCUMEN)
					_cDocumento := "BD "+AllTrim(SE5TMP->E5_DOCUMEN)
				ElseIf !EMPTY(SE5TMP->E5_NUMCHEQ)
					_cDocumento := "CH "+AllTrim(SE5TMP->E5_NUMCHEQ)
				EndIf
			EndIf
			
			//TRatamento para nใo acumular a somat๓ria dos titulo FL na concilia็ใo.
			IF (SE5TMP->E5_TIPODOC =='BA' .And. SE5TMP->E5_TIPO =='FL ' )
				_nTotal := SE5TMP->E5_VALOR
			Else
				_nTotal := _nTotal + SE5TMP->E5_VALOR
			Endif
			
			aAdd(aPags,{ .F., STOD(SE5TMP->E5_DTDISPO), _cOpera, _cDocumento, SE5TMP->E5_VALOR,0,SE5TMP->REGSE5})
			
			//TRatamento para nใo acumular a somat๓ria dos titulo FL na concilia็ใo.
			IF (SE5TMP->E5_TIPODOC =='BA' .And. SE5TMP->E5_TIPO =='FL ' )
				If _nTotal <> 0
					For _nI:=_nConta to Len(aPags)
						aPags[_nI,6] := _nTotal
					Next _nI
					_nConta := Len(aPags) + 1
				EndIf
			EndIf
			
			dbSelectArea("SE5TMP")
			DbSkip()
		EndDo
		If _nTotal <> 0
			For _nI:=_nConta to Len(aPags)
				aPags[_nI,6] := _nTotal
			Next _nI
			
			_nConta := Len(aPags) + 1
		EndIf
		
	Enddo
	
	//                             "Data"            ,"Operacao/Beneficiario"        ,"Documento"       ,"Valor"                                           ,"Valor Bordero"
	// 1                           2                  3                               4                  5                                                  6
	// .F.                        ,SE5TMP->E5_DTDISPO,_cOpera                        ,_cDocumento       ,SE5TMP->E5_VALOR                                  , _nTotal
	// aPags[oLbx1:nAt,1],oOk,oNo),aPags[oLbx1:nAt,2],aPags[oLbx1:nAt,3]             ,aPags[oLbx1:nAt,4],Transform(aPags[oLbx1:nAt,5],"@EZ 999,999,999.99"),Transform(aPags[oLbx1:nAt,5],"@EZ 999,999,999.99")
	
	dbSelectArea("SE5TMP")
	DbCloseArea()
	
	If Len(aPags) > 0
		
		If Len(aPags)>=2  // Refazer os acumulados
			_cAntes := ""
			For _nI:=1 to Len(aPags)-1
				If aPags[_nI,4] <> aPags[_nI+1,4] .And. _cAntes <> aPags[_nI,4]
					aPags[_nI,6] := aPags[_nI,5]
				EndIf
				_cAntes := aPags[_nI,4]
			Next _nI
			If aPags[Len(aPags)-1,4] <> aPags[Len(aPags),4]
				aPags[Len(aPags),6] := aPags[Len(aPags),5]
			EndIf
		EndIf
		
		DEFINE MSDIALOG oDlg FROM  31,58 TO 360,695 TITLE "Escolha Movimentacao Contas a Pagar a conciliar " PIXEL
		@ 05,05 LISTBOX oLbx1 FIELDS HEADER "","Data","Operacao/Beneficiario","Documento","Valor","Valor Bordero" SIZE 310, 130 OF oDlg PIXEL ;
			ON DBLCLICK ( C6A20MRK())
		
		oLbx1:SetArray(aPags)
		oLbx1:bLine := { || {If(aPags[oLbx1:nAt,1],oOk,oNo),aPags[oLbx1:nAt,2],aPags[oLbx1:nAt,3],aPags[oLbx1:nAt,4],Transform(aPags[oLbx1:nAt,5],"@EZ 999,999,999.99"),Transform(aPags[oLbx1:nAt,6],"@EZ 999,999,999.99") } }
		oLbx1:nFreeze  := 1
		//TODO
		DEFINE SBUTTON FROM 140, 198 TYPE 11 ENABLE OF oDlg ACTION (C6A20CLA(),_lRet :=.T.,oDlg:End())
		DEFINE SBUTTON FROM 140, 228 TYPE 17 ENABLE OF oDlg ACTION C6A20ME5()
		DEFINE SBUTTON FROM 140, 258 TYPE 1  ENABLE OF oDlg ACTION (C6A20CE5(),_lRet :=.T.,oDlg:End())
		DEFINE SBUTTON FROM 140, 288 TYPE 2  ENABLE OF oDlg ACTION (_lRet :=.F.,oDlg:End())
		
		ACTIVATE MSDIALOG oDlg CENTERED
	Else
		_lRet := .F.
		MsgInfo("Jแ Conciliados!","Aten็ใo")
	Endif
	
	RestArea(aArea)
	
Return(_lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณCFINA20   บAutor  ณMicrosiga           บ Data ณ  10/24/07   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                        บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

static Function C6A20MRK()
Local _nI := 0
	_lFlag := aPags[oLbx1:nAt,1]
	If Left(aPags[oLbx1:nAt,4],2) $ "BD"
		For _nI:=1 to Len(aPags)
			If aPags[oLbx1:nAt,4] == aPags[_nI,4]
				If _lFlag
					aPags[_nI,1] := .F.
				Else
					aPags[_nI,1] := .T.
				EndIf
			EndIf
		Next _nI
	Else
		If _lFlag
			aPags[oLbx1:nAt,1] := .F.
		Else
			aPags[oLbx1:nAt,1] := .T.
		EndIf
	EndIf
	oLbx1:Refresh(.T.)
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณCFINA20   บAutor  ณMicrosiga           บ Data ณ  10/24/07   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                        บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

static Function C6A20ME5
Local _nI := 0
	For _nI:=1 to Len(aPags)
		If aPags[_nI,1]
			aPags[_nI,1] := .F.
		Else
			aPags[_nI,1] := .T.
		EndIf
	Next _nI
	oLbx1:Refresh(.T.)
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณCFINA20   บAutor  ณMicrosiga           บ Data ณ  10/24/07   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                        บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

static Function C6A20CE5
	Local  _aArea := GetArea()
	Local _cKey	:= ''
	Local _nI	:= 0
	For _nI:=1 to Len(aPags)
		DbSelectarea("SE5")
		If aPags[_nI,1]
			dbGoto(aPags[_nI,7])
			RecLock("SE5", .F.)
			SE5->E5_DTDISPO:=dDataBase
			SE5->E5_RECONC := "x"
			msUnLock()
			
			DbSelectarea("SE5")
			dbGoto(aPags[_nI,7])
			If ALLTRIM(SE5->E5_TIPO) == 'SPB'
				
				_cKey	:= SE5->(E5_FILIAL+E5_TIPODOC+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+DTOS(E5_DATA)+E5_CLIFOR+E5_LOJA+E5_SEQ)
				
				DbSelectarea("SE2")
				DbSetOrder(1)
				DbSeek(xFilial("SE2")+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO+SE5->E5_CLIFOR+SE5->E5_LOJA,.F.)
				
				DbSelectArea("SA2")
				DbSetOrder(1)
				DbSeek(xFilial("SA2")+SE2->E2_FORNECE,.F.)
				
				C6E20CTB(aPags, _cKey)
				
			EndIf
		EndIf
	Next _nI
	RestArea(_aArea)
	oLbx1:Refresh(.T.)
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณCFINA20   บAutor  ณMicrosiga           บ Data ณ  10/24/07   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

STATIC Function C6A20CLA()
	Local _nI := 0
	
	For _nI:=1 to Len(aPags)
		
		DbSelectarea("SE5")
		
		_cDocum   := aPags[_nI,4]
		_cValDoc  := aPags[_nI,5]
		
		If aPags[_nI,1]
			
			DbSelectarea("SE5")
			dbGoto(aPags[_nI,7])
			If ALLTRIM(SE5->E5_TIPO) <> 'SPB'
				MsgBox("Este registro nao pode ser Editada !!!")
				Exit
			EndIf
			
			@ 33,25 TO 110,349 Dialog oDlg01 Title "Reclassificao do Titulo"
			@ 01,05 TO 035, 128
			@ 08,08 Say "Documento: "
			@ 08,50 Say _cDocum
			@ 17,08 Say "Valor: "
			@ 17,50 Get _cValDoc Picture "@E 999,999.99" size 50,20 VALID C6A20DOC()
			@ 05, 132 BMPBUTTON TYPE 1 Action C6A20END(_lClose:=.T.)
			Activate Dialog oDlg01 CENTERED
			
			If _lClose
				dbGoto(aPags[_nI,7])
				RecLock("SE5", .F.)
				SE5->E5_VALOR := _cValDoc
				msUnLock()
				
				DbSelectarea("SE2")
				DbSetOrder(1)
				DbSeek(xFilial("SE2")+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO+SE5->E5_CLIFOR+SE5->E5_LOJA,.F.)
				
				RecLock("SE2", .F.)
				SE2->E2_SALDO	:= SE2->E2_VALOR - _cValDoc
				SE2->E2_VALLIQ	:= _cValDoc
				msUnLock()
			EndIf
		EndIf
	Next _nI
	oLbx1:Refresh(.T.)
Return

STATIC Function C6A20END()
	oDlg01:End()
Return(.T.)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณCFINA20   บAutor  ณMicrosiga           บ Data ณ  10/24/07   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                        บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function C6A20DOC()
	
	_lRet 	:= .T.
	_lClose	:= .F.
	
	DbSelectArea("SE5")
	dbGoto(aPags[_nI,7])
	
	DbSelectarea("SE2")
	DbSetOrder(1)
	DbSeek(xFilial("SE2")+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO+SE5->E5_CLIFOR+SE5->E5_LOJA,.F.)
	
	If _cValDoc > SE2->E2_VALOR
		MsgBox("Valor Maior que o Original!!!")
		_lRet := .F.
	ElseIf _cValDoc <= 0
		MsgBox("Valor nao pode ser Zero!!!")
		_lRet := .F.
	EndIf
	
Return(_lRet)

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C6A20CTB
Rotina de contabiliza็ใo do processo de concilia็ใo bancaria.
@author  	Totvs
@since     	26/01/2016
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function C6E20CTB(aPags, _cKey)
	
	LOCAL cPadrao		:= "Z0B"
	LOCAL cLote		:= "008850"
	LOCAL cArquivo 	:= ''
	LOCAL nTotal   	:= 0
	LOCAL nHdlPrv		:= 0
	Local _nI		:= 0
	//	Local _cKey		:= ''
	
	If VerPadrao(cPadrao)
		
		nHdlPrv := HeadProva( cLote,;
			"CFINA20",;
			Substr(cUsuario,7,6),;
			@cArquivo )
		
		For _nI := 1 to Len(aPags)
			
			nTotal += DetProva( nHdlPrv,;
				cPadrao,;
				"CFINA20",;
				cLote,;
				/*nLinha*/,;
				/*lExecuta*/,;
				/*cCriterio*/,;
				/*lRateio*/,;
				/* */,;
				/*aCT5*/,;
				/*lPosiciona*/,;
				/*@aFlagCTB*/,;
				/*aTabRecOri*/,;
				/*aDadosProva*/ )
		Next _nI
		
		IF nTotal > 0
			RodaProva(nHdlPrv,nTotal)
			cA100Incl(cArquivo,nHdlPrv,3,cLote,.T.,.F.)
		ENDIF
		
	ENDIF
	
Return
