#include 'totvs.ch'

/*/{Protheus.doc} CFINR084
Informações sobre as Movimentações da Cobrança do Titulo
@type user function
@version 12.1.25
@author elton.alves@totvs.com.br
@since 09/06/2020
/*/
user function CFINR084()

    Private cNome        := StrTran(Procname(),'U_','')
    Private cTitulo      := "Informações sobre as Movimentações da Cobrança do Titulo"
    Private cPerguntas   := StrTran(Procname(),'U_','')
    Private bBlocoCodigo := { || ReportExec() }
    Private cDescricao   := "Informações sobre as Movimentações da Cobrança do Titulo"
    Private oReport      := TReport():New( cNome, cTitulo, cPerguntas, bBlocoCodigo, cDescricao )
    Private cAlias       := GetNextAlias()
    Private oSection     := TRSection():New( oReport , cDescricao, { cAlias },,.F. )
    Private aCampos      := {}

    Pergunte( cPerguntas, .F. )

    oReport:SetLandscape()

    oReport:ShowParamPage( )

    oReport:PrintDialog()

Return

/*/{Protheus.doc} ReportExec
Executa o relatório
@type static function
@version 12.1.25
@author elton.alves@totvs.com.br
@since 09/06/2020
/*/
static function ReportExec()

    Local nX := 0

    BuildAlias()

    oReport:SetMeter(0)

    For nX := 1 To ( cAlias )->( FCount() )

        cCampo   := ( cAlias )->( FieldName( nX ) )
        cTitulo  := aCampos[nX][1]
        cPicture := aCampos[nX][2]
        nTamanho := aCampos[nX][3]

        TRCell():New( oSection, cCampo, cAlias, cTitulo, cPicture, nTamanho  )

    Next nX

    TRFunction():New(oSection:Cell("E1_VLCRUZ"),NIL,"SUM",,,,,.F.,.T.)

    oSection:init()

    (cAlias)->( DbGoTop() )

    Do While ! ( cAlias )->( Eof() )

        For nX := 1 To ( cAlias )->( FCount() )

            cCampo   := ( cAlias )->( FieldName( nX ) )
            xValor   := ( cAlias )->&( FieldName( nX ) )

            oSection:Cell( cCampo ):SetValue( xValor )

        Next nX

        oSection:Printline()

        (cAlias)->(dbSkip())

    End Do

    oSection:Finish()

    (cAlias)->( DbCloseArea() )

return

/*/{Protheus.doc} BuildAlias
Monta o Alias usado pelo relatório
@type static function
@version 12.1.25
@author elton.alves@totvs.com.br
@since 09/06/2020
/*/
static function BuildAlias()

    Local cQuery   := ''
    Local cPicture := '@!'
    Local nTamanho := 0
    Local aField   := {} // Variável utilizada para aplicar a função TcSetField nos campos de data ao fim da execução da query
    Local nX       := 0

    cQuery += " SELECT  "

/*---------------------------------------------------------------*/
    cPicture := '@!'
    nTamanho := Len( 'Tipo de Cobrança' )

    aAdd( aCampos, { 'Tipo de Cobrança', cPicture, nTamanho } )

    cQuery += " '', "

/*---------------------------------------------------------------*/
    cPicture := '@!'
    nTamanho := 10

    aAdd( aCampos, { 'Data Faturamento', cPicture, nTamanho } )

    aAdd( aField, { 'E1_EMISSAO', 'D' } )

    cQuery += " SE1.E1_EMISSAO, "

 /*---------------------------------------------------------------*/   
    cPicture := '@!'
    nTamanho := 10

    aAdd( aCampos, { 'Data Vencimento', cPicture, nTamanho } )

    aAdd( aField, { 'E1_VENCREA', 'D' } )

    cQuery += " SE1.E1_VENCREA, "

 /*---------------------------------------------------------------*/   
    cPicture := '@!'
    nTamanho := TamSx3('EE_CODCART')[1] + TamSx3('E1_NUMBCO')[1] + 1

    aAdd( aCampos, { 'Numero Boleto FCB', cPicture, nTamanho } )

    cQuery += " SEE.EE_CODCART + '-' + SE1.E1_NUMBCO, "

/*---------------------------------------------------------------*/    
    cPicture := X3Picture('E1_VLCRUZ')
    nTamanho := TamSx3('E1_VLCRUZ')[1]

    aAdd( aCampos, { 'Valor Cobrado FCB CI', cPicture, nTamanho } )

    cQuery += " SE1.E1_VLCRUZ, "

/*---------------------------------------------------------------*/    
    cPicture := X3Picture('E1_VLCRUZ')
    nTamanho := TamSx3('E1_VLCRUZ')[1]

    aAdd( aCampos, { 'Valor Cobrado Titulo FCB Ressarcimento Folha ', cPicture, nTamanho } )

    cQuery += " ( SELECT TOP 1 SE1PBA.E1_VLCRUZ FROM " + RetSqlName("SE1") + " SE1PBA "
    cQuery += "   WHERE SE1PBA.D_E_L_E_T_ = '' "
    cQuery += "   AND   SE1PBA.E1_XIDFOLH = SE1.E1_XIDFOLH ), "

/*---------------------------------------------------------------*/    
    cPicture := X3Picture('E1_DECRESC')
    nTamanho := TamSx3('E1_DECRESC')[1]

    aAdd( aCampos, { 'Desconto', cPicture, nTamanho } )

    cQuery += " SE1.E1_DECRESC, "

/*---------------------------------------------------------------*/    
    cPicture := X3Picture('E1_ACRESC')
    nTamanho := TamSx3('E1_ACRESC')[1]

    aAdd( aCampos, { 'Juros', cPicture, nTamanho } )

    cQuery += " SE1.E1_ACRESC, "

/*---------------------------------------------------------------*/    
    cPicture := X3Picture('E1_VLCRUZ')
    nTamanho := TamSx3('E1_VLCRUZ')[1]

    aAdd( aCampos, { 'Titulo FCB CI Cancelado', cPicture, nTamanho } )

    cQuery += " 0, "

/*---------------------------------------------------------------*/    
    cPicture := X3Picture('E1_VLCRUZ')
    nTamanho := TamSx3('E1_VLCRUZ')[1]

    aAdd( aCampos, { 'Titulo FCB Ressarcimento Cancelado', cPicture, nTamanho } )

    cQuery += " 0, "

/*---------------------------------------------------------------*/    
    cPicture := X3Picture('E1_VLCRUZ')
    nTamanho := TamSx3('E1_VLCRUZ')[1]

    aAdd( aCampos, { 'Valor Titulo FCB Recebido', cPicture, nTamanho } )

    cQuery += " 0, "

/*---------------------------------------------------------------*/    
    cPicture := '@!'
    nTamanho := 10

    aAdd( aCampos, { 'Data Liquidação/Cancelamento', cPicture, nTamanho } )

    aAdd( aField, { 'DT_LIQ_CANC', 'D' } )

    cQuery += " '" + DtoS( Date() ) + "' DT_LIQ_CANC, "

/*---------------------------------------------------------------*/    
    cPicture := '@!'
    nTamanho := Len( 'SITUACAO' )

    aAdd( aCampos, { 'Situação', cPicture, nTamanho } )

    cQuery += " 'SITUACAO' "

/*---------------------------------------------------------------*/

    cQuery += " FROM " + RetSqlName("SE1") + " SE1 "

    cQuery += " INNER JOIN " + RetSqlName("SEE") + " SEE "
    cQuery += " ON  SEE.D_E_L_E_T_ = SE1.D_E_L_E_T_   "
    cQuery += " AND SEE.EE_CODIGO  = SE1.E1_PORTADO   "
    cQuery += " AND SEE.EE_AGENCIA = SE1.E1_AGEDEP    "
    cQuery += " AND SEE.EE_CONTA   = SE1.E1_CONTA     "
    cQuery += " AND SEE.EE_SUBCTA  = '001' "

    cQuery += " WHERE SE1.D_E_L_E_T_ = '' "
    cQuery += " AND   SE1.E1_PREFIXO = 'NF' "
    cQuery += " AND   SE1.E1_EMISSAO BETWEEN '" + DtoS( MV_PAR01 ) + "' AND '"+DtoS( MV_PAR02 )+"' "
    cQuery += " AND   SE1.E1_VENCREA BETWEEN '" + DtoS( MV_PAR03 ) + "' AND '"+DtoS( MV_PAR04 )+"' "

    MsgRun( 'Banco de Dados Processando a Query ...', 'Aguarde ...', { || MPSysOpenQuery( cQuery, cAlias ) } )

    For nX := 1 To Len( aField )

        TcSetField( cAlias, aField[ nX, 1 ], aField[ nX, 2 ] )

    Next nX

return