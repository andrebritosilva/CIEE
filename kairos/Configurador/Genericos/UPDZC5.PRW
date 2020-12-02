#INCLUDE "protheus.ch"

#DEFINE SIMPLES Char( 39 )
#DEFINE DUPLAS  Char( 34 )

#DEFINE CSSBOTAO	"QPushButton { color: #024670; "+;
"    border-image: url(rpo:fwstd_btn_nml.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"+;
"QPushButton:pressed {	color: #FFFFFF; "+;
"    border-image: url(rpo:fwstd_btn_prd.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"

//--------------------------------------------------------------------
/*/{Protheus.doc} UPDZC5
Função de update exclusivo da tabela ZC5 (SIX e SX3)

@author TOTVS Protheus
@since  20/08/2020
@obs    Gerado por EXPORDIC - V.6.5.0.3 EFS / Upd. V.5.1.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
User Function UPDZC5( cEmpAmb, cFilAmb )

Local   aSay      := {}
Local   aButton   := {}
Local   aMarcadas := {}
Local   cTitulo   := "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS"
Local   cDesc1    := "Esta rotina tem como função fazer  a atualização  dos dicionários do Sistema ( SX?/SIX )"
Local   cDesc2    := "Este processo deve ser executado em modo EXCLUSIVO, ou seja não podem haver outros"
Local   cDesc3    := "usuários  ou  jobs utilizando  o sistema.  É EXTREMAMENTE recomendavél  que  se  faça um"
Local   cDesc4    := "BACKUP  dos DICIONÁRIOS  e da  BASE DE DADOS antes desta atualização, para que caso "
Local   cDesc5    := "ocorram eventuais falhas, esse backup possa ser restaurado."
//Local   cDesc6    := ""
//Local   cDesc7    := ""
Local   cMsg      := ""
Local   lOk       := .F.
Local   lAuto     := ( cEmpAmb <> NIL .or. cFilAmb <> NIL )

Private oMainWnd  := NIL
Private oProcess  := NIL

#IFDEF TOP
    TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
#ENDIF

__cInterNet := NIL
__lPYME     := .F.

Set Dele On

// Mensagens de Tela Inicial
aAdd( aSay, cDesc1 )
aAdd( aSay, cDesc2 )
aAdd( aSay, cDesc3 )
aAdd( aSay, cDesc4 )
aAdd( aSay, cDesc5 )
//aAdd( aSay, cDesc6 )
//aAdd( aSay, cDesc7 )

// Botoes Tela Inicial
aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )

If lAuto
	lOk := .T.
Else
	FormBatch(  cTitulo,  aSay,  aButton )
EndIf

If lOk

	If GetVersao(.F.) < "12" .OR. ( FindFunction( "MPDicInDB" ) .AND. !MPDicInDB() )
		cMsg := "Este update NÃO PODE ser executado neste Ambiente." + CRLF + CRLF + ;
				"Os arquivos de dicionários se encontram em formato ISAM (" + GetDbExtension() + ") e este update está preparado " + ;
				"para atualizar apenas ambientes com dicionários no Banco de Dados."

		If lAuto
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( "LOG DA ATUALIZAÇÃO DOS DICIONÁRIOS" )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( cMsg )
			ConOut( DToC(Date()) + "|" + Time() + cMsg )
		Else
			MsgInfo( cMsg )
		EndIf

		Return NIL
	EndIf

	If lAuto
		aMarcadas :={{ cEmpAmb, cFilAmb, "" }}
	Else

		aMarcadas := EscEmpresa()
	EndIf

	If !Empty( aMarcadas )
		If lAuto .OR. MsgNoYes( "Confirma a atualização dos dicionários ?", cTitulo )
			oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas, lAuto ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
			oProcess:Activate()

			If lAuto
				If lOk
					MsgStop( "Atualização Realizada.", "UPKAIROS" )
				Else
					MsgStop( "Atualização não Realizada.", "UPKAIROS" )
				EndIf
				dbCloseAll()
			Else
				If lOk
					Final( "Atualização Realizada." )
				Else
					Final( "Atualização não Realizada." )
				EndIf
			EndIf

		Else
			Final( "Atualização não Realizada." )

		EndIf

	Else
		Final( "Atualização não Realizada." )

	EndIf

EndIf

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSTProc
Função de processamento da gravação dos arquivos

@author TOTVS Protheus
@since  20/08/2020
@obs    Gerado por EXPORDIC - V.6.5.0.3 EFS / Upd. V.5.1.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSTProc( lEnd, aMarcadas, lAuto )
Local   aInfo     := {}
Local   aRecnoSM0 := {}
//Local   cAux      := ""
Local   cFile     := ""
//Local   cFileLog  := ""
Local   cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
Local   cTCBuild  := "TCGetBuild"
Local   cTexto    := ""
Local   cTopBuild := ""
Local   lOpen     := .F.
Local   lRet      := .T.
Local   nI        := 0
Local   nPos      := 0
//Local   nRecno    := 0
Local   nX        := 0
Local   oDlg      := NIL
Local   oFont     := NIL
Local   oMemo     := NIL

Private aArqUpd   := {}

If ( lOpen := MyOpenSm0(.T.) )

	dbSelectArea( "SM0" )
	dbGoTop()

	While !SM0->( EOF() )
		// Só adiciona no aRecnoSM0 se a empresa for diferente
		If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
		   .AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
			aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
		EndIf
		SM0->( dbSkip() )
	End

	SM0->( dbCloseArea() )

	If lOpen

		For nI := 1 To Len( aRecnoSM0 )

			If !( lOpen := MyOpenSm0(.F.) )
				MsgStop( "Atualização da empresa " + aRecnoSM0[nI][2] + " não efetuada." )
				Exit
			EndIf

			SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

			RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

			lMsFinalAuto := .F.
			lMsHelpAuto  := .F.

			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( "LOG DA ATUALIZAÇÃO DOS DICIONÁRIOS" )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " " )
			AutoGrLog( " Dados Ambiente" )
			AutoGrLog( " --------------------" )
			AutoGrLog( " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt )
			AutoGrLog( " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) )
			AutoGrLog( " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) )
			AutoGrLog( " DataBase...........: " + DtoC( dDataBase ) )
			AutoGrLog( " Data / Hora Ínicio.: " + DtoC( Date() )  + " / " + Time() )
			AutoGrLog( " Environment........: " + GetEnvServer()  )
			AutoGrLog( " StartPath..........: " + GetSrvProfString( "StartPath", "" ) )
			AutoGrLog( " RootPath...........: " + GetSrvProfString( "RootPath" , "" ) )
			AutoGrLog( " Versão.............: " + GetVersao(.T.) )
			AutoGrLog( " Usuário TOTVS .....: " + __cUserId + " " +  cUserName )
			AutoGrLog( " Computer Name......: " + GetComputerName() )

			aInfo   := GetUserInfo()
			If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
				AutoGrLog( " " )
				AutoGrLog( " Dados Thread" )
				AutoGrLog( " --------------------" )
				AutoGrLog( " Usuário da Rede....: " + aInfo[nPos][1] )
				AutoGrLog( " Estação............: " + aInfo[nPos][2] )
				AutoGrLog( " Programa Inicial...: " + aInfo[nPos][5] )
				AutoGrLog( " Environment........: " + aInfo[nPos][6] )
				AutoGrLog( " Conexão............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) ) )
			EndIf
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " " )

			If !lAuto
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF )
			EndIf

			oProcess:SetRegua1( 8 )


			oProcess:IncRegua1( "Dicionário de arquivos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )

			FSAtuSX3()

			oProcess:IncRegua1( "Dicionário de índices" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSIX()

			oProcess:IncRegua1( "Dicionário de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			oProcess:IncRegua2( "Atualizando campos/índices" )

			// Alteração física dos arquivos
			__SetX31Mode( .F. )

			If FindFunction(cTCBuild)
				cTopBuild := &cTCBuild.()
			EndIf

			For nX := 1 To Len( aArqUpd )

				If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
					If ( ( aArqUpd[nX] >= "NQ " .AND. aArqUpd[nX] <= "NZZ" ) .OR. ( aArqUpd[nX] >= "O0 " .AND. aArqUpd[nX] <= "NZZ" ) ) .AND.;
						!aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
						TcInternal( 25, "CLOB" )
					EndIf
				EndIf

				If Select( aArqUpd[nX] ) > 0
					dbSelectArea( aArqUpd[nX] )
					dbCloseArea()
				EndIf

				X31UpdTable( aArqUpd[nX] )

				If __GetX31Error()
					Alert( __GetX31Trace() )
					MsgStop( "Ocorreu um erro desconhecido durante a atualização da tabela : " + aArqUpd[nX] + ". Verifique a integridade do dicionário e da tabela.", "ATENÇÃO" )
					AutoGrLog( "Ocorreu um erro desconhecido durante a atualização da estrutura da tabela : " + aArqUpd[nX] )
				EndIf

				If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
					TcInternal( 25, "OFF" )
				EndIf

			Next nX

			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time() )
			AutoGrLog( Replicate( "-", 128 ) )

			RpcClearEnv()

		Next nI

		If !lAuto

			cTexto := LeLog()

			Define Font oFont Name "Mono AS" Size 5, 12

			Define MsDialog oDlg Title "Atualização concluida." From 3, 0 to 340, 417 Pixel

			@ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel
			oMemo:bRClicked := { || AllwaysTrue() }
			oMemo:oFont     := oFont

			Define SButton From 153, 175 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
			Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
			MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel

			Activate MsDialog oDlg Center

		EndIf

	EndIf

Else

	lRet := .F.

EndIf

Return lRet

//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX3
Função de processamento da gravação do SX3 - Campos

@author TOTVS Protheus
@since  20/08/2020
@obs    Gerado por EXPORDIC - V.6.5.0.3 EFS / Upd. V.5.1.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX3()
Local aEstrut   := {}
Local aSX3      := {}
Local cAlias    := ""
Local cAliasAtu := ""
Local cSeqAtu   := ""
Local cX3Campo  := ""
Local cX3Dado   := ""
Local nI        := 0
Local nJ        := 0
Local nPosArq   := 0
Local nPosCpo   := 0
Local nPosOrd   := 0
Local nPosSXG   := 0
Local nPosTam   := 0
Local nPosVld   := 0
Local nSeqAtu   := 0
Local nTamSeek  := Len( SX3->X3_CAMPO )

AutoGrLog( "Ínicio da Atualização" + " SX3" + CRLF )

aEstrut := { { "X3_ARQUIVO", 0 }, { "X3_ORDEM"  , 0 }, { "X3_CAMPO"  , 0 }, { "X3_TIPO"   , 0 }, { "X3_TAMANHO", 0 }, { "X3_DECIMAL", 0 }, { "X3_TITULO" , 0 }, ;
             { "X3_TITSPA" , 0 }, { "X3_TITENG" , 0 }, { "X3_DESCRIC", 0 }, { "X3_DESCSPA", 0 }, { "X3_DESCENG", 0 }, { "X3_PICTURE", 0 }, { "X3_VALID"  , 0 }, ;
             { "X3_USADO"  , 0 }, { "X3_RELACAO", 0 }, { "X3_F3"     , 0 }, { "X3_NIVEL"  , 0 }, { "X3_RESERV" , 0 }, { "X3_CHECK"  , 0 }, { "X3_TRIGGER", 0 }, ;
             { "X3_PROPRI" , 0 }, { "X3_BROWSE" , 0 }, { "X3_VISUAL" , 0 }, { "X3_CONTEXT", 0 }, { "X3_OBRIGAT", 0 }, { "X3_VLDUSER", 0 }, { "X3_CBOX"   , 0 }, ;
             { "X3_CBOXSPA", 0 }, { "X3_CBOXENG", 0 }, { "X3_PICTVAR", 0 }, { "X3_WHEN"   , 0 }, { "X3_INIBRW" , 0 }, { "X3_GRPSXG" , 0 }, { "X3_FOLDER" , 0 }, ;
             { "X3_CONDSQL", 0 }, { "X3_CHKSQL" , 0 }, { "X3_IDXSRV" , 0 }, { "X3_ORTOGRA", 0 }, { "X3_TELA"   , 0 }, { "X3_POSLGT" , 0 }, { "X3_IDXFLD" , 0 }, ;
             { "X3_AGRUP"  , 0 }, { "X3_MODAL"  , 0 }, { "X3_PYME"   , 0 } }

aEval( aEstrut, { |x| x[2] := SX3->( FieldPos( x[1] ) ) } )

aAdd( aSX3, {{'ZC5',.F.},{'01',.F.},{'ZC5_FILIAL',.F.},{'C',.F.},{4,.F.},{0,.F.},{'Filial',.F.},{'Sucursal',.F.},{'Branch',.F.},{'Filial do Sistema',.F.},{'Sucursal',.F.},{'Branch of the System',.F.},{'@!',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x',.F.},{'',.F.},{'',.F.},{1,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'',.F.},{'',.F.},{'  x',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'033',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'02',.F.},{'ZC5_DATA',.F.},{'D',.F.},{8,.F.},{0,.F.},{'DT Entrada',.F.},{'DT Entrada',.F.},{'DT Entrada',.F.},{'DT Entrada',.F.},{'DT Entrada',.F.},{'DT Entrada',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'03',.F.},{'ZC5_DTCANC',.F.},{'D',.F.},{8,.F.},{0,.F.},{'DT Cancel.',.F.},{'DT Cancel.',.F.},{'DT Cancel.',.F.},{'Data de cancelamento',.F.},{'Data de cancelamento',.F.},{'Data de cancelamento',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'04',.F.},{'ZC5_RPSSOC',.F.},{'C',.F.},{9,.F.},{0,.F.},{'Codigo SOE',.F.},{'Codigo SOE',.F.},{'Codigo SOE',.F.},{'Codigo da RPS no SOE',.F.},{'Codigo da RPS no SOE',.F.},{'Codigo da RPS no SOE',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'V',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'05',.F.},{'ZC5_SERIE',.F.},{'C',.F.},{3,.F.},{0,.F.},{'Serie N.F.',.F.},{'Serie N.F.',.F.},{'Serie N.F.',.F.},{'Serie da Nota Fiscal',.F.},{'Serie da Nota Fiscal',.F.},{'Serie da Nota Fiscal',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'06',.F.},{'ZC5_NOTA',.F.},{'C',.F.},{9,.F.},{0,.F.},{'Nota Fiscal',.F.},{'Nota Fiscal',.F.},{'Nota Fiscal',.F.},{'Numero da Nota Fiscal',.F.},{'Numero da Nota Fiscal',.F.},{'Numero da Nota Fiscal',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'07',.F.},{'ZC5_CLIENT',.F.},{'C',.F.},{6,.F.},{0,.F.},{'Cod.Cliente',.F.},{'Cod.Cliente',.F.},{'Cod.Cliente',.F.},{'Codigo do cliente',.F.},{'Codigo do cliente',.F.},{'Codigo do cliente',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'08',.F.},{'ZC5_LOJA',.F.},{'C',.F.},{2,.F.},{0,.F.},{'Loja',.F.},{'Loja',.F.},{'Loja',.F.},{'Loja do Cliente',.F.},{'Loja do Cliente',.F.},{'Loja do Cliente',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'09',.F.},{'ZC5_NOMCLI',.F.},{'C',.F.},{60,.F.},{0,.F.},{'Nome Cliente',.F.},{'Nome Cliente',.F.},{'Nome Cliente',.F.},{'Nome do cliente',.F.},{'Nome do cliente',.F.},{'Nome do cliente',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'10',.F.},{'ZC5_ESTADO',.F.},{'C',.F.},{2,.F.},{0,.F.},{'Estado Ref.',.F.},{'Estado Ref.',.F.},{'Estado Ref.',.F.},{'Estado de Referencia',.F.},{'Estado de Referencia',.F.},{'Estado de Referencia',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'11',.F.},{'ZC5_VALOR',.F.},{'N',.F.},{14,.F.},{2,.F.},{'Vlr.Contabil',.F.},{'Vlr.Contabil',.F.},{'Vlr.Contabil',.F.},{'Vlr.Contabil',.F.},{'Vlr.Contabil',.F.},{'Vlr.Contabil',.F.},{'@E 99,999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'12',.F.},{'ZC5_CODNFE',.F.},{'C',.F.},{50,.F.},{0,.F.},{'Cd.Ver. NF-e',.F.},{'Cd.Ver. NF-e',.F.},{'Cd.Ver. NF-e',.F.},{'Codigo verificacao NF-e',.F.},{'Codigo verificacao NF-e',.F.},{'Codigo verificacao NF-e',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'13',.F.},{'ZC5_NFELET',.F.},{'C',.F.},{20,.F.},{0,.F.},{'NF Eletr.',.F.},{'NF Eletr.',.F.},{'NF Eletr.',.F.},{'Nota Fiscal Eletronica',.F.},{'Nota Fiscal Eletronica',.F.},{'Nota Fiscal Eletronica',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'14',.F.},{'ZC5_CHVNFE',.F.},{'C',.F.},{44,.F.},{0,.F.},{'Chave NFe',.F.},{'Chave NFe',.F.},{'Chave NFe',.F.},{'Chave da NFe SEFAZ',.F.},{'Chave da NFe SEFAZ',.F.},{'Chave da NFe SEFAZ',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'15',.F.},{'ZC5_DESRET',.F.},{'C',.F.},{250,.F.},{0,.F.},{'Desc retorno',.F.},{'Desc retorno',.F.},{'Desc retorno',.F.},{'Desc do retorno da Nfse',.F.},{'Desc do retorno da Nfse',.F.},{'Desc do retorno da Nfse',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'16',.F.},{'ZC5_DESMOT',.F.},{'C',.F.},{240,.F.},{0,.F.},{'Mot. Cancel',.F.},{'Mot. Cancel',.F.},{'Mot. Cancel',.F.},{'Motivo de cancelamento',.F.},{'Motivo de cancelamento',.F.},{'Motivo de cancelamento',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'17',.F.},{'ZC5_STATUS',.F.},{'C',.F.},{1,.F.},{0,.F.},{'Status',.F.},{'Status',.F.},{'Status',.F.},{'Status',.F.},{'Status',.F.},{'Status',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'18',.F.},{'ZC5_MSGLOG',.F.},{'C',.F.},{150,.F.},{0,.F.},{'Msg de Log',.F.},{'Msg de Log',.F.},{'Msg de Log',.F.},{'Mensagem de log',.F.},{'Mensagem de log',.F.},{'Mensagem de log',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'  x',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'19',.F.},{'ZC5_MSGENT',.F.},{'M',.F.},{10,.F.},{0,.F.},{'Msg Entrada',.F.},{'Msg Entrada',.F.},{'Msg Entrada',.F.},{'Mensagem de entrada',.F.},{'Mensagem de entrada',.F.},{'Mensagem de entrada',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'20',.F.},{'ZC5_MSGSAI',.F.},{'M',.F.},{10,.F.},{0,.F.},{'Msg Saida',.F.},{'Msg Saida',.F.},{'Msg Saida',.F.},{'Mensagem de saida',.F.},{'Mensagem de saida',.F.},{'Mensagem de saida',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'21',.F.},{'ZC5_HORINI',.F.},{'C',.F.},{8,.F.},{0,.F.},{'Hr. Ini.Fat.',.F.},{'Hr. Ini.Fat.',.F.},{'Hr. Ini.Fat.',.F.},{'Hra inicio do faturamento',.F.},{'Hra inicio do faturamento',.F.},{'Hra inicio do faturamento',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'22',.F.},{'ZC5_HORFIM',.F.},{'C',.F.},{8,.F.},{0,.F.},{'Hr. Fim.Fat.',.F.},{'Hr. Fim.Fat.',.F.},{'Hr. Fim.Fat.',.F.},{'Hra Final do faturamento',.F.},{'Hra Final do faturamento',.F.},{'Hra Final do faturamento',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'23',.F.},{'ZC5_HORRET',.F.},{'C',.F.},{8,.F.},{0,.F.},{'Hr. Ret.Soe.',.F.},{'Hr. Ret.Soe.',.F.},{'Hr. Ret.Soe.',.F.},{'Hra retorno do SOE',.F.},{'Hra retorno do SOE',.F.},{'Hra retorno do SOE',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'24',.F.},{'ZC5_UUID',.F.},{'C',.F.},{36,.F.},{0,.F.},{'UUID',.F.},{'UUID',.F.},{'UUID',.F.},{'UUID',.F.},{'UUID',.F.},{'UUID',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x     x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'  x',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'25',.F.},{'ZC5_EVMAIL',.F.},{'C',.F.},{1,.F.},{0,.F.},{'Enviou Email',.F.},{'Enviou Email',.F.},{'Enviou Email',.F.},{'Enviou Email',.F.},{'Enviou Email',.F.},{'Enviou Email',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x     x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'  x',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'26',.F.},{'ZC5_MUNPRE',.F.},{'C',.F.},{7,.F.},{0,.F.},{'Cod.Mun.Pres',.F.},{'Cod.Mun.Pres',.F.},{'Cod.Mun.Pres',.F.},{'Municipio de Prestacao',.F.},{'Municipio de Prestacao',.F.},{'Municipio de Prestacao',.F.},{'@!',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x     x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'27',.F.},{'ZC5_MUNDES',.F.},{'C',.F.},{60,.F.},{0,.F.},{'Municipio',.F.},{'Municipio',.F.},{'Municipio',.F.},{'Municipio',.F.},{'Municipio',.F.},{'Municipio',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'POSICIONE("CC2",1,XFILIAL("CC2")+ZC5->(ZC5_ESTADO+ZC5_MUNPRE),"CC2_MUN")',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'28',.F.},{'ZC5_MSGNOT',.F.},{'M',.F.},{10,.F.},{0,.F.},{'Msg NF SOE',.F.},{'Msg NF SOE',.F.},{'Msg NF SOE',.F.},{'Mensagem NF SOE',.F.},{'Mensagem NF SOE',.F.},{'Mensagem NF SOE',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'29',.F.},{'ZC5_EMAIL',.F.},{'C',.F.},{50,.F.},{0,.F.},{'E-mail',.F.},{'E-mail',.F.},{'E-mail',.F.},{'E-mail Cliente',.F.},{'E-mail Cliente',.F.},{'E-mail Cliente',.F.},{'@!',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'30',.F.},{'ZC5_WF',.F.},{'C',.F.},{1,.F.},{0,.F.},{'WorkFlow',.F.},{'WorkFlow',.F.},{'WorkFlow',.F.},{'WorkFlow',.F.},{'WorkFlow',.F.},{'WorkFlow',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'31',.F.},{'ZC5_IDCONT',.F.},{'C',.F.},{15,.F.},{0,.F.},{'ID Contrato',.F.},{'ID Contrato',.F.},{'ID Contrato',.F.},{'ID do Contrato',.F.},{'ID do Contrato',.F.},{'ID do Contrato',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'  x',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'32',.F.},{'ZC5_CONFAT',.F.},{'C',.F.},{15,.F.},{0,.F.},{'Conf. Fatur.',.F.},{'Conf. Fatur.',.F.},{'Conf. Fatur.',.F.},{'ID Configuracao Faturamen',.F.},{'ID Configuracao Faturamen',.F.},{'ID Configuracao Faturamen',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'  x',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'33',.F.},{'ZC5_CONCOB',.F.},{'C',.F.},{15,.F.},{0,.F.},{'Conf.Cobranc',.F.},{'Conf.Cobranc',.F.},{'Conf.Cobranc',.F.},{'ID Configuracao Cobranca',.F.},{'ID Configuracao Cobranca',.F.},{'ID Configuracao Cobranca',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'  x',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'34',.F.},{'ZC5_DATVEN',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Dt. Vencto.',.F.},{'Dt. Vencto.',.F.},{'Dt. Vencto.',.F.},{'Data Vencimento',.F.},{'Data Vencimento',.F.},{'Data Vencimento',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'  x',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'35',.F.},{'ZC5_TIPPRO',.F.},{'C',.F.},{1,.F.},{0,.F.},{'Tipo Produto',.F.},{'Tipo Produto',.F.},{'Tipo Produto',.F.},{'Tipo Produto',.F.},{'Tipo Produto',.F.},{'Tipo Produto',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'  x',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'36',.F.},{'ZC5_LOCCON',.F.},{'C',.F.},{15,.F.},{0,.F.},{'Id Local Con',.F.},{'Id Local Con',.F.},{'Id Local Con',.F.},{'Id do Local Contrato',.F.},{'Id do Local Contrato',.F.},{'Id do Local Contrato',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'  x',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'37',.F.},{'ZC5_LOGCOM',.F.},{'M',.F.},{10,.F.},{0,.F.},{'Log.Completo',.F.},{'Log.Completo',.F.},{'Log.Completo',.F.},{'Log.Completo',.F.},{'Log.Completo',.F.},{'Log.Completo',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'  x',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'38',.F.},{'ZC5_BCOFAT',.F.},{'C',.F.},{3,.F.},{0,.F.},{'Bco. Faturam',.F.},{'Bco. Faturam',.F.},{'Bco. Faturam',.F.},{'Banco Faturamento',.F.},{'Banco Faturamento',.F.},{'Banco Faturamento',.F.},{'@!',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'  x',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'39',.F.},{'ZC5_LOTE',.F.},{'C',.F.},{20,.F.},{0,.F.},{'Lote',.F.},{'Lote',.F.},{'Lote',.F.},{'Lote',.F.},{'Lote',.F.},{'Lote',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'40',.F.},{'ZC5_LOTRAS',.F.},{'C',.F.},{16,.F.},{0,.F.},{'Rastreamento',.F.},{'Rastreamento',.F.},{'Rastreamento',.F.},{'Lote de Rastreamento',.F.},{'Lote de Rastreamento',.F.},{'Lote de Rastreamento',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'S',.F.},{'A',.F.},{'R',.F.},{'  x',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'41',.F.},{'ZC5_RAMAL',.F.},{'C',.F.},{5,.F.},{0,.F.},{'Ramal',.F.},{'Ramal',.F.},{'Ramal',.F.},{'Ramal',.F.},{'Ramal',.F.},{'Ramal',.F.},{'@!',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'42',.F.},{'ZC5_IDFOLH',.F.},{'C',.F.},{15,.F.},{0,.F.},{'Id Folha',.F.},{'Id Folha',.F.},{'Id Folha',.F.},{'Id Folha',.F.},{'Id Folha',.F.},{'Id Folha',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'43',.F.},{'ZC5_NUMSOC',.F.},{'C',.F.},{15,.F.},{0,.F.},{'Id. Fluig',.F.},{'Id Fluig',.F.},{'Id Fluig',.F.},{'Numero Solicitacao Fluig',.F.},{'Numero Solicitacao Fluig',.F.},{'Numero Solicitacao Fluig',.F.},{'@!',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'44',.F.},{'ZC5_COMPET',.F.},{'C',.F.},{6,.F.},{0,.F.},{'Competencia',.F.},{'Competencia',.F.},{'Competencia',.F.},{'Competencia',.F.},{'Competencia',.F.},{'Competencia',.F.},{'@!',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'  x',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'45',.F.},{'ZC5_CONPAG',.F.},{'C',.F.},{3,.F.},{0,.F.},{'Cond.Pgto',.F.},{'Cond.Pgto',.F.},{'Cond.Pgto',.F.},{'Condicao de pagamento',.F.},{'Condicao de pagamento',.F.},{'Condicao de pagamento',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'46',.F.},{'ZC5_PARC1',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 1',.F.},{'Cuota 1',.F.},{'Installment',.F.},{'Valor da Parcela 1',.F.},{'Valor de la cuota 1',.F.},{'Installment Value 1',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'47',.F.},{'ZC5_IDFATU',.F.},{'C',.F.},{19,.F.},{0,.F.},{'ID Fatura',.F.},{'ID Fatura',.F.},{'ID Fatura',.F.},{'ID Fatura',.F.},{'ID Fatura',.F.},{'ID Fatura',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'V',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'48',.F.},{'ZC5_DATA1',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento1',.F.},{'Vencimient1',.F.},{'MaturityDt1',.F.},{'Vencimento da Parcela 1',.F.},{'Vencimiento de la Cuota1',.F.},{'Installment Due Date1',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'49',.F.},{'ZC5_PARC2',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 2',.F.},{'Cuota 2',.F.},{'Installment',.F.},{'Valor da Parcela 2',.F.},{'Valor de la cuota 2',.F.},{'Installment Value 2',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'50',.F.},{'ZC5_DATA2',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento2',.F.},{'Vencimient2',.F.},{'MaturityDt2',.F.},{'Vencimento da Parcela 2',.F.},{'Vencimiento de la Cuota2',.F.},{'Installment Due Date2',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'51',.F.},{'ZC5_PARC3',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 3',.F.},{'Cuota 3',.F.},{'Installment',.F.},{'Valor da Parcela 3',.F.},{'Valor de la cuota 3',.F.},{'Installment Value 3',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'52',.F.},{'ZC5_DATA3',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento3',.F.},{'Vencimient3',.F.},{'MaturityDt3',.F.},{'Vencimento da Parcela 3',.F.},{'Vencimiento de la Cuota3',.F.},{'Installment Due Date3',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'53',.F.},{'ZC5_PARC4',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 4',.F.},{'Cuota 4',.F.},{'Installment',.F.},{'Valor da Parcela 4',.F.},{'Valor de la cuota 4',.F.},{'Installment Value 4',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'54',.F.},{'ZC5_DATA4',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento4',.F.},{'Vencimient4',.F.},{'MaturityDt4',.F.},{'Vencimento da Parcela 4',.F.},{'Vencimiento de la Cuota4',.F.},{'Installment Due Date4',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'55',.F.},{'ZC5_PARC5',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 5',.F.},{'Cuota 5',.F.},{'Installment',.F.},{'Valor da Parcela 5',.F.},{'Valor de la cuota 5',.F.},{'Installment Value 5',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'56',.F.},{'ZC5_DATA5',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento5',.F.},{'Vencimient5',.F.},{'MaturityDt5',.F.},{'Vencimento da Parcela 5',.F.},{'Vencimiento de la Cuota5',.F.},{'Installment Due Date5',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'57',.F.},{'ZC5_PARC6',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 6',.F.},{'Cuota 6',.F.},{'Installment',.F.},{'Valor da Parcela 6',.F.},{'Valor de la cuota 6',.F.},{'Installment Value 6',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'58',.F.},{'ZC5_DATA6',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento6',.F.},{'Vencimient6',.F.},{'MaturityDt6',.F.},{'Vencimento da Parcela 6',.F.},{'Vencimiento de la Cuota6',.F.},{'Installment Due Date6',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'59',.F.},{'ZC5_PARC7',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 7',.F.},{'Cuota 7',.F.},{'Installment',.F.},{'Valor da Parcela 7',.F.},{'Valor de la cuota 7',.F.},{'Installment Value 7',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'60',.F.},{'ZC5_DATA7',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento7',.F.},{'Vencimient7',.F.},{'MaturityDt7',.F.},{'Vencimento da Parcela 7',.F.},{'Vencimiento de la Cuota7',.F.},{'Installment Due Date7',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'61',.F.},{'ZC5_PARC8',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 8',.F.},{'Cuota 8',.F.},{'Installment',.F.},{'Valor da Parcela 8',.F.},{'Valor de la cuota 8',.F.},{'Installment Value 8',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'62',.F.},{'ZC5_DATA8',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento8',.F.},{'Vencimient8',.F.},{'MaturityDt8',.F.},{'Vencimento da Parcela 8',.F.},{'Vencimiento de la Cuota8',.F.},{'Installment Due Date8',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'63',.F.},{'ZC5_PARC9',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 9',.F.},{'Cuota 9',.F.},{'Installment',.F.},{'alor da Parcela 9',.F.},{'Valor de la cuota 9',.F.},{'Installment Value 9',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'64',.F.},{'ZC5_DATA9',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento9',.F.},{'Vencimient9',.F.},{'MaturityDt9',.F.},{'Vencimento da Parcela 9',.F.},{'Vencimiento de la Cuota9',.F.},{'Installment Due Date9',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'65',.F.},{'ZC5_PARCA',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 10',.F.},{'Cuota 10',.F.},{'Installment',.F.},{'Valor da Parcela 10',.F.},{'Valor de la cuota 10',.F.},{'Installment Value 10',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'66',.F.},{'ZC5_DATAA',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento10',.F.},{'Vencimient10',.F.},{'MaturityDt10',.F.},{'Vencimento da Parcela 10',.F.},{'Vencimiento de la Cuota10',.F.},{'Installment Due Date10',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'67',.F.},{'ZC5_PARCB',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 11',.F.},{'Cuota 11',.F.},{'Installment',.F.},{'Valor da Parcela 11',.F.},{'Valor de la cuota 11',.F.},{'Installment Value 11',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'68',.F.},{'ZC5_DATAB',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento11',.F.},{'Vencimient11',.F.},{'MaturityDt11',.F.},{'Vencimento da Parcela 11',.F.},{'Vencimiento de la Cuota11',.F.},{'Installment Due Date11',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'69',.F.},{'ZC5_PARCC',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 12',.F.},{'Cuota 12',.F.},{'Installment',.F.},{'Valor da Parcela 12',.F.},{'Valor de la cuota 12',.F.},{'Installment Value 12',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'70',.F.},{'ZC5_DATAC',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento12',.F.},{'Vencimient12',.F.},{'MaturityDt12',.F.},{'Vencimento da Parcela 12',.F.},{'Vencimiento de la Cuota12',.F.},{'Installment Due Date12',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'71',.F.},{'ZC5_PARCD',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 13',.F.},{'Cuota 13',.F.},{'Installment',.F.},{'Valor da Parcela 13',.F.},{'Valor de la cuota 13',.F.},{'Installment Value 13',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'72',.F.},{'ZC5_DATAD',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento13',.F.},{'Vencimient13',.F.},{'MaturityDt13',.F.},{'Vencimento da Parcela 13',.F.},{'Vencimiento de la Cuota13',.F.},{'Installment Due Date13',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'73',.F.},{'ZC5_PARCE',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 14',.F.},{'Cuota 14',.F.},{'Installment',.F.},{'Valor da Parcela 14',.F.},{'Valor de la cuota 14',.F.},{'Installment Value 14',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'74',.F.},{'ZC5_DATAE',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento14',.F.},{'Vencimient14',.F.},{'MaturityDt14',.F.},{'Vencimento da Parcela 14',.F.},{'Vencimiento de la Cuota14',.F.},{'Installment Due Date14',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'75',.F.},{'ZC5_PARCF',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 15',.F.},{'Cuota 15',.F.},{'Installment',.F.},{'Valor da Parcela 15',.F.},{'Valor de la cuota 15',.F.},{'Installment Value 15',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'76',.F.},{'ZC5_DATAF',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento15',.F.},{'Vencimient15',.F.},{'MaturityDt15',.F.},{'Vencimento da Parcela 15',.F.},{'Vencimiento de la Cuota15',.F.},{'Installment Due Date15',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'77',.F.},{'ZC5_PARCG',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 16',.F.},{'Cuota 16',.F.},{'Installment',.F.},{'Valor da Parcela 16',.F.},{'Valor de la cuota 16',.F.},{'Installment Value 16',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'78',.F.},{'ZC5_DATAG',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento16',.F.},{'Vencimient16',.F.},{'MaturityDt16',.F.},{'Vencimento da Parcela 16',.F.},{'Vencimiento de la Cuota16',.F.},{'Installment Due Date16',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'79',.F.},{'ZC5_PARCH',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 17',.F.},{'Cuota 17',.F.},{'Installment',.F.},{'Valor da Parcela 17',.F.},{'Valor de la cuota 17',.F.},{'Installment Value 17',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'80',.F.},{'ZC5_DATAH',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento17',.F.},{'Vencimient17',.F.},{'MaturityDt17',.F.},{'Vencimento da Parcela 17',.F.},{'Vencimiento de la Cuota17',.F.},{'Installment Due Date17',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'81',.F.},{'ZC5_PARCI',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 18',.F.},{'Cuota 18',.F.},{'Installment',.F.},{'Valor da Parcela 18',.F.},{'Valor de la cuota 18',.F.},{'Installment Value 18',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'82',.F.},{'ZC5_DATAI',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento18',.F.},{'Vencimient18',.F.},{'MaturityDt18',.F.},{'Vencimento da Parcela 18',.F.},{'Vencimiento de la Cuota18',.F.},{'Installment Due Date18',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'83',.F.},{'ZC5_PARCJ',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 19',.F.},{'Cuota 19',.F.},{'Installment',.F.},{'Valor da Parcela 19',.F.},{'Valor de la cuota 19',.F.},{'Installment Value 19',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'84',.F.},{'ZC5_DATAJ',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento19',.F.},{'Vencimient19',.F.},{'MaturityDt19',.F.},{'Vencimento da Parcela 19',.F.},{'Vencimiento de la Cuota19',.F.},{'Installment Due Date19',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'85',.F.},{'ZC5_PARCK',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 20',.F.},{'Cuota 20',.F.},{'Installment',.F.},{'Valor da Parcela 20',.F.},{'Valor de la cuota 20',.F.},{'Installment Value 20',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'86',.F.},{'ZC5_DATAK',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento20',.F.},{'Vencimient20',.F.},{'MaturityDt20',.F.},{'Vencimento da Parcela 20',.F.},{'Vencimiento de la Cuota20',.F.},{'Installment Due Date20',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'87',.F.},{'ZC5_PARCL',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 21',.F.},{'Cuota 21',.F.},{'Installment',.F.},{'Valor da Parcela 21',.F.},{'Valor de la cuota 21',.F.},{'Installment Value 21',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'88',.F.},{'ZC5_DATAL',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento21',.F.},{'Vencimient21',.F.},{'MaturityDt21',.F.},{'Vencimento da Parcela 21',.F.},{'Vencimiento de la Cuota21',.F.},{'Installment Due Date21',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'89',.F.},{'ZC5_PARCM',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 22',.F.},{'Cuota 22',.F.},{'Installment',.F.},{'Valor da Parcela 22',.F.},{'Valor de la cuota 22',.F.},{'Installment Value 22',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'90',.F.},{'ZC5_DATAM',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento22',.F.},{'Vencimient22',.F.},{'MaturityDt22',.F.},{'Vencimento da Parcela 22',.F.},{'Vencimiento de la Cuota22',.F.},{'Installment Due Date22',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'91',.F.},{'ZC5_PARCN',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 23',.F.},{'Cuota 23',.F.},{'Installment',.F.},{'Valor da Parcela 23',.F.},{'Valor de la cuota 23',.F.},{'Installment Value 23',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'92',.F.},{'ZC5_DATAN',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento23',.F.},{'Vencimient23',.F.},{'MaturityDt23',.F.},{'Vencimento da Parcela 23',.F.},{'Vencimiento de la Cuota23',.F.},{'Installment Due Date23',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'93',.F.},{'ZC5_PARCO',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 24',.F.},{'Cuota 24',.F.},{'Installment',.F.},{'Valor da Parcela 24',.F.},{'Valor de la cuota 24',.F.},{'Installment Value 24',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'94',.F.},{'ZC5_DATAO',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento24',.F.},{'Vencimient24',.F.},{'MaturityDt24',.F.},{'Vencimento da Parcela 24',.F.},{'Vencimiento de la Cuota24',.F.},{'Installment Due Date24',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'95',.F.},{'ZC5_PARCP',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 25',.F.},{'Cuota 25',.F.},{'Installment',.F.},{'Valor da Parcela 25',.F.},{'Valor de la cuota 25',.F.},{'Installment Value 25',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'96',.F.},{'ZC5_DATAP',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento25',.F.},{'Vencimient25',.F.},{'MaturityDt25',.F.},{'Vencimento da Parcela 25',.F.},{'Vencimiento de la Cuota25',.F.},{'Installment Due Date25',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'97',.F.},{'ZC5_PARCQ',.F.},{'N',.F.},{12,.F.},{2,.F.},{'Parcela 26',.F.},{'Cuota 26',.F.},{'Installment',.F.},{'Valor da Parcela 26',.F.},{'Valor de la cuota 26',.F.},{'Installment Value 26',.F.},{'@E 999,999,999.99',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )
aAdd( aSX3, {{'ZC5',.F.},{'98',.F.},{'ZC5_DATAQ',.F.},{'D',.F.},{8,.F.},{0,.F.},{'Vencimento26',.F.},{'Vencimient26',.F.},{'MaturityDt26',.F.},{'Vencimento da Parcela 26',.F.},{'Vencimiento de la Cuota26',.F.},{'Installment Due Date26',.F.},{'',.F.},{'',.F.},{'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x',.F.},{'',.F.},{'',.F.},{0,.F.},{'xxxxxx x',.F.},{'',.F.},{'',.F.},{'U',.F.},{'N',.F.},{'A',.F.},{'R',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'N',.F.},{'',.F.},{'',.F.},{'',.F.}} )

//
// Atualizando dicionário
//
nPosArq := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ARQUIVO" } )
nPosOrd := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ORDEM"   } )
nPosCpo := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_CAMPO"   } )
nPosTam := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_TAMANHO" } )
nPosSXG := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_GRPSXG"  } )
nPosVld := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_VALID"   } )

aSort( aSX3,,, { |x,y| x[nPosArq][1]+x[nPosOrd][1]+x[nPosCpo][1] < y[nPosArq][1]+y[nPosOrd][1]+y[nPosCpo][1] } )

oProcess:SetRegua2( Len( aSX3 ) )

dbSelectArea( "SX3" )
dbSetOrder( 2 )
cAliasAtu := ""

For nI := 1 To Len( aSX3 )

	//
	// Verifica se o campo faz parte de um grupo e ajusta tamanho
	//
	If !Empty( aSX3[nI][nPosSXG][1] )
		SXG->( dbSetOrder( 1 ) )
		If SXG->( MSSeek( aSX3[nI][nPosSXG][1] ) )
			If aSX3[nI][nPosTam][1] <> SXG->XG_SIZE
				aSX3[nI][nPosTam][1] := SXG->XG_SIZE
				AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo][1] + " NÃO atualizado e foi mantido em [" + ;
				AllTrim( Str( SXG->XG_SIZE ) ) + "]" + CRLF + ;
				" por pertencer ao grupo de campos [" + SXG->XG_GRUPO + "]" + CRLF )
			EndIf
		EndIf
	EndIf

	SX3->( dbSetOrder( 2 ) )

	If !( aSX3[nI][nPosArq][1] $ cAlias )
		cAlias += aSX3[nI][nPosArq][1] + "/"
		aAdd( aArqUpd, aSX3[nI][nPosArq][1] )
	EndIf

	If !SX3->( dbSeek( PadR( aSX3[nI][nPosCpo][1], nTamSeek ) ) )

		//
		// Busca ultima ocorrencia do alias
		//
		If ( aSX3[nI][nPosArq][1] <> cAliasAtu )
			cSeqAtu   := "00"
			cAliasAtu := aSX3[nI][nPosArq][1]

			dbSetOrder( 1 )
			SX3->( dbSeek( cAliasAtu + "ZZ", .T. ) )
			dbSkip( -1 )

			If ( SX3->X3_ARQUIVO == cAliasAtu )
				cSeqAtu := SX3->X3_ORDEM
			EndIf

			nSeqAtu := Val( RetAsc( cSeqAtu, 3, .F. ) )
		EndIf

		nSeqAtu++
		cSeqAtu := RetAsc( Str( nSeqAtu ), 2, .T. )

		RecLock( "SX3", .T. )
		For nJ := 1 To Len( aSX3[nI] )
			If     nJ == nPosOrd  // Ordem
				SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), cSeqAtu ) )

			ElseIf aEstrut[nJ][2] > 0
				SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ][1] ) )

			EndIf
		Next nJ

		dbCommit()
		MsUnLock()

		AutoGrLog( "Criado campo " + aSX3[nI][nPosCpo][1] )

	Else

		//
		// Verifica se o campo faz parte de um grupo e ajsuta tamanho
		//
		If !Empty( SX3->X3_GRPSXG ) .AND. SX3->X3_GRPSXG <> aSX3[nI][nPosSXG][1]
			SXG->( dbSetOrder( 1 ) )
			If SXG->( MSSeek( SX3->X3_GRPSXG ) )
				If aSX3[nI][nPosTam][1] <> SXG->XG_SIZE
					aSX3[nI][nPosTam][1] := SXG->XG_SIZE
					AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo][1] + " NÃO atualizado e foi mantido em [" + ;
					AllTrim( Str( SXG->XG_SIZE ) ) + "]"+ CRLF + ;
					"   por pertencer ao grupo de campos [" + SX3->X3_GRPSXG + "]" + CRLF )
				EndIf
			EndIf
		EndIf

		//
		// Verifica todos os campos
		//
		For nJ := 1 To Len( aSX3[nI] )

			If aSX3[nI][nJ][2]
				cX3Campo := AllTrim( aEstrut[nJ][1] )
				cX3Dado  := SX3->( FieldGet( aEstrut[nJ][2] ) )

				If  aEstrut[nJ][2] > 0 .AND. ;
					PadR( StrTran( AllToChar( cX3Dado ), " ", "" ), 250 ) <> ;
					PadR( StrTran( AllToChar( aSX3[nI][nJ][1] ), " ", "" ), 250 ) .AND. ;
					!cX3Campo  == "X3_ORDEM"

					AutoGrLog( "Alterado campo " + aSX3[nI][nPosCpo][1] + CRLF + ;
					"   " + PadR( cX3Campo, 10 ) + " de [" + AllToChar( cX3Dado ) + "]" + CRLF + ;
					"            para [" + AllToChar( aSX3[nI][nJ][1] )           + "]" + CRLF )

					RecLock( "SX3", .F. )
					FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ][1] )
					MsUnLock()
				EndIf
			EndIf
		Next

	EndIf

	oProcess:IncRegua2( "Atualizando Campos de Tabelas (SX3)..." )

Next nI

AutoGrLog( CRLF + "Final da Atualização" + " SX3" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSIX
Função de processamento da gravação do SIX - Indices

@author TOTVS Protheus
@since  20/08/2020
@obs    Gerado por EXPORDIC - V.6.5.0.3 EFS / Upd. V.5.1.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSIX()
Local aEstrut   := {}
Local aSIX      := {}
Local lAlt      := .F.
Local lDelInd   := .F.
Local nI        := 0
Local nJ        := 0

AutoGrLog( "Ínicio da Atualização" + " SIX" + CRLF )

aEstrut := { "INDICE" , "ORDEM" , "CHAVE", "DESCRICAO", "DESCSPA"  , ;
             "DESCENG", "PROPRI", "F3"   , "NICKNAME" , "SHOWPESQ" }

aAdd( aSIX, {'ZC5','8','ZC5_IDFATU','ID Fatura','ID Fatura','ID Fatura','U','','IDFATURAME','S'} )
aAdd( aSIX, {'ZC5','9','ZC5_NUMSOC','Numero Solicitacao','NUM. SOC.','NUM. SOC.','U','','','S'} )

//
// Atualizando dicionário
//
oProcess:SetRegua2( Len( aSIX ) )

dbSelectArea( "SIX" )
SIX->( dbSetOrder( 1 ) )

For nI := 1 To Len( aSIX )

	lAlt    := .F.
	lDelInd := .F.

	If !SIX->( dbSeek( aSIX[nI][1] + aSIX[nI][2] ) )
		AutoGrLog( "Índice criado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
	Else
		lAlt := .T.
		aAdd( aArqUpd, aSIX[nI][1] )
		If !StrTran( Upper( AllTrim( CHAVE )       ), " ", "" ) == ;
		    StrTran( Upper( AllTrim( aSIX[nI][3] ) ), " ", "" )
			AutoGrLog( "Chave do índice alterado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
			lDelInd := .T. // Se for alteração precisa apagar o indice do banco
		EndIf
	EndIf

	RecLock( "SIX", !lAlt )
	For nJ := 1 To Len( aSIX[nI] )
		If FieldPos( aEstrut[nJ] ) > 0
			FieldPut( FieldPos( aEstrut[nJ] ), aSIX[nI][nJ] )
		EndIf
	Next nJ
	MsUnLock()

	dbCommit()

	If lDelInd
		TcInternal( 60, RetSqlName( aSIX[nI][1] ) + "|" + RetSqlName( aSIX[nI][1] ) + aSIX[nI][2] )
	EndIf

	oProcess:IncRegua2( "Atualizando índices..." )

Next nI

AutoGrLog( CRLF + "Final da Atualização" + " SIX" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL

//--------------------------------------------------------------------
/*/{Protheus.doc} EscEmpresa
Função genérica para escolha de Empresa, montada pelo SM0

@return aRet Vetor contendo as seleções feitas.
             Se não for marcada nenhuma o vetor volta vazio

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function EscEmpresa()

//---------------------------------------------
// Parâmetro  nTipo
// 1 - Monta com Todas Empresas/Filiais
// 2 - Monta só com Empresas
// 3 - Monta só com Filiais de uma Empresa
//
// Parâmetro  aMarcadas
// Vetor com Empresas/Filiais pré marcadas
//
// Parâmetro  cEmpSel
// Empresa que será usada para montar seleção
//---------------------------------------------
Local   aRet      := {}
Local   aSalvAmb  := GetArea()
Local   aSalvSM0  := {}
Local   aVetor    := {}
Local   cMascEmp  := "??"
Local   cVar      := ""
Local   lChk      := .F.
//Local   lOk       := .F.
Local   lTeveMarc := .F.
Local   oNo       := LoadBitmap( GetResources(), "LBNO" )
Local   oOk       := LoadBitmap( GetResources(), "LBOK" )
Local   oDlg, oChkMar, oLbx, oMascEmp, oSay
Local   oButDMar, oButInv, oButMarc, oButOk, oButCanc

Local   aMarcadas := {}


If !MyOpenSm0(.F.)
	Return aRet
EndIf


dbSelectArea( "SM0" )
aSalvSM0 := SM0->( GetArea() )
dbSetOrder( 1 )
dbGoTop()

While !SM0->( EOF() )

	If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
		aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
	EndIf

	dbSkip()
End

RestArea( aSalvSM0 )

Define MSDialog  oDlg Title "" From 0, 0 To 280, 395 Pixel

oDlg:cToolTip := "Tela para Múltiplas Seleções de Empresas/Filiais"

oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualização"

@ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", " ", "Empresa" Size 178, 095 Of oDlg Pixel
oLbx:SetArray(  aVetor )
oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
aVetor[oLbx:nAt, 2], ;
aVetor[oLbx:nAt, 4]}}
oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
oLbx:cToolTip   :=  oDlg:cTitle
oLbx:lHScroll   := .F. // NoScroll

@ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos" Message "Marca / Desmarca"+ CRLF + "Todos" Size 40, 007 Pixel Of oDlg;
on Click MarcaTodos( lChk, @aVetor, oLbx )

// Marca/Desmarca por mascara
@ 113, 51 Say   oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
@ 112, 80 MSGet oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
Message "Máscara Empresa ( ?? )"  Of oDlg
oSay:cToolTip := oMascEmp:cToolTip

@ 128, 10 Button oButInv    Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Inverter Seleção" Of oDlg
oButInv:SetCss( CSSBOTAO )
@ 128, 50 Button oButMarc   Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Marcar usando" + CRLF + "máscara ( ?? )"    Of oDlg
oButMarc:SetCss( CSSBOTAO )
@ 128, 80 Button oButDMar   Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Desmarcar usando" + CRLF + "máscara ( ?? )" Of oDlg
oButDMar:SetCss( CSSBOTAO )
@ 112, 157  Button oButOk   Prompt "Processar"  Size 32, 12 Pixel Action (  RetSelecao( @aRet, aVetor ), IIf( Len( aRet ) > 0, oDlg:End(), MsgStop( "Ao menos um grupo deve ser selecionado", "UPKAIROS" ) ) ) ;
Message "Confirma a seleção e efetua" + CRLF + "o processamento" Of oDlg
oButOk:SetCss( CSSBOTAO )
@ 128, 157  Button oButCanc Prompt "Cancelar"   Size 32, 12 Pixel Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) ;
Message "Cancela o processamento" + CRLF + "e abandona a aplicação" Of oDlg
oButCanc:SetCss( CSSBOTAO )

Activate MSDialog  oDlg Center

RestArea( aSalvAmb )
dbSelectArea( "SM0" )
dbCloseArea()

Return  aRet


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaTodos
Função auxiliar para marcar/desmarcar todos os ítens do ListBox ativo

@param lMarca  Contéudo para marca .T./.F.
@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaTodos( lMarca, aVetor, oLbx )
Local  nI := 0

For nI := 1 To Len( aVetor )
	aVetor[nI][1] := lMarca
Next nI

oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} InvSelecao
Função auxiliar para inverter a seleção do ListBox ativo

@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function InvSelecao( aVetor, oLbx )
Local  nI := 0

For nI := 1 To Len( aVetor )
	aVetor[nI][1] := !aVetor[nI][1]
Next nI

oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} RetSelecao
Função auxiliar que monta o retorno com as seleções

@param aRet    Array que terá o retorno das seleções (é alterado internamente)
@param aVetor  Vetor do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function RetSelecao( aRet, aVetor )
Local  nI    := 0

aRet := {}
For nI := 1 To Len( aVetor )
	If aVetor[nI][1]
		aAdd( aRet, { aVetor[nI][2] , aVetor[nI][3], aVetor[nI][2] +  aVetor[nI][3] } )
	EndIf
Next nI

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaMas
Função para marcar/desmarcar usando máscaras

@param oLbx     Objeto do ListBox
@param aVetor   Vetor do ListBox
@param cMascEmp Campo com a máscara (???)
@param lMarDes  Marca a ser atribuída .T./.F.

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaMas( oLbx, aVetor, cMascEmp, lMarDes )
Local cPos1 := SubStr( cMascEmp, 1, 1 )
Local cPos2 := SubStr( cMascEmp, 2, 1 )
Local nPos  := oLbx:nAt
Local nZ    := 0

For nZ := 1 To Len( aVetor )
	If cPos1 == "?" .or. SubStr( aVetor[nZ][2], 1, 1 ) == cPos1
		If cPos2 == "?" .or. SubStr( aVetor[nZ][2], 2, 1 ) == cPos2
			aVetor[nZ][1] := lMarDes
		EndIf
	EndIf
Next

oLbx:nAt := nPos
oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} VerTodos
Função auxiliar para verificar se estão todos marcados ou não

@param aVetor   Vetor do ListBox
@param lChk     Marca do CheckBox do marca todos (referncia)
@param oChkMar  Objeto de CheckBox do marca todos

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function VerTodos( aVetor, lChk, oChkMar )
Local lTTrue := .T.
Local nI     := 0

For nI := 1 To Len( aVetor )
	lTTrue := IIf( !aVetor[nI][1], .F., lTTrue )
Next nI

lChk := IIf( lTTrue, .T., .F. )
oChkMar:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MyOpenSM0
Função de processamento abertura do SM0 modo exclusivo

@author TOTVS Protheus
@since  20/08/2020
@obs    Gerado por EXPORDIC - V.6.5.0.3 EFS / Upd. V.5.1.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MyOpenSM0(lShared)
Local lOpen := .F.
Local nLoop := 0

If FindFunction( "OpenSM0Excl" )
	For nLoop := 1 To 20
		If OpenSM0Excl(,.F.)
			lOpen := .T.
			Exit
		EndIf
		Sleep( 500 )
	Next nLoop
Else
	For nLoop := 1 To 20
		dbUseArea( .T., , "SIGAMAT.EMP", "SM0", lShared, .F. )

		If !Empty( Select( "SM0" ) )
			lOpen := .T.
			dbSetIndex( "SIGAMAT.IND" )
			Exit
		EndIf
		Sleep( 500 )
	Next nLoop
EndIf

If !lOpen
	MsgStop( "Não foi possível a abertura da tabela " + ;
	IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), "ATENÇÃO" )
EndIf

Return lOpen


//--------------------------------------------------------------------
/*/{Protheus.doc} LeLog
Função de leitura do LOG gerado com limitacao de string

@author TOTVS Protheus
@since  20/08/2020
@obs    Gerado por EXPORDIC - V.6.5.0.3 EFS / Upd. V.5.1.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function LeLog()
Local cRet  := ""
Local cFile := NomeAutoLog()
Local cAux  := ""

FT_FUSE( cFile )
FT_FGOTOP()

While !FT_FEOF()

	cAux := FT_FREADLN()

	If Len( cRet ) + Len( cAux ) < 1048000
		cRet += cAux + CRLF
	Else
		cRet += CRLF
		cRet += Replicate( "=" , 128 ) + CRLF
		cRet += "Tamanho de exibição maxima do LOG alcançado." + CRLF
		cRet += "LOG Completo no arquivo " + cFile + CRLF
		cRet += Replicate( "=" , 128 ) + CRLF
		Exit
	EndIf

	FT_FSKIP()
End

FT_FUSE()

Return cRet
