#include 'totvs.ch'

/*/{Protheus.doc} CFINR083
Informações sobre e Estagiario/Aprendiz
@type user function
@version 12.1.25
@author elton.alves@totvs.com.br
@since 09/06/2020
/*/
user function CFINR083()

    Private cNome        := StrTran(Procname(),'U_','')
    Private cTitulo      := "Informações sobre e Estagiario/Aprendiz"
    Private cPerguntas   := StrTran(Procname(),'U_','')
    Private bBlocoCodigo := { || ReportExec() }
    Private cDescricao   := "Informações sobre e Estagiario/Aprendiz"
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

    //Definindo Totais do relatório
    bFormula := { |a, b, c, oTrFunc| If( oTrFunc:oCell:GetValue() > 0 , 1, 0  ) }

    TRFunction():New(oSection:Cell("RA_XID")      ,,"COUNT",,'Quantidade de TCE/TCA'          ,,         ,.F.,.T.)
    TRFunction():New(oSection:Cell("RD_VALOR_004"),,"SUM"  ,,'Quantidade de Bolsa Auxilio'    ,,bFormula ,.F.,.T.)
    TRFunction():New(oSection:Cell("RD_VALOR_004"),,"SUM"  ,,'Total de Bolsa Auxílio'         ,,         ,.F.,.T.)
    TRFunction():New(oSection:Cell("RD_VALOR_277"),,"SUM"  ,,'Total de Auxilio Transporte'    ,,         ,.F.,.T.)
    TRFunction():New(oSection:Cell("RD_VALOR_509"),,"SUM"  ,,'Total de Imposto de Renda'      ,,         ,.F.,.T.)
    TRFunction():New(oSection:Cell("RD_VALOR_554"),,"SUM"  ,,'Total Pensão Alimenticia'       ,,         ,.F.,.T.)
    TRFunction():New(oSection:Cell("RD_VALOR_J99"),,"SUM"  ,,'Total de Bolsa Auxilio a Pagar' ,,         ,.F.,.T.)

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
    Local cPicture := ''
    Local nTamanho := 0
    Local aField   := {} // Variável utilizada para aplicar a função TcSetField nos campos de data ao fim da execução da query
    Local nX       := 0

    cQuery += " SELECT DISTINCT "

/*---------------------------------------------------------------*/
    cPicture := GetSx3Cache( 'RA_XIDCONT', 'X3_PICTURE' )
    nTamanho := GetSx3Cache( 'RA_XIDCONT', 'X3_TAMANHO' )

    aAdd( aCampos, { 'Contrato', cPicture, nTamanho } )

    cQuery += " SRA.RA_XIDCONT, "

/*---------------------------------------------------------------*/
    cPicture := GetSx3Cache( 'RA_XIDLOCT', 'X3_PICTURE' )
    nTamanho := GetSx3Cache( 'RA_XIDLOCT', 'X3_TAMANHO' )

    aAdd( aCampos, { 'Local', cPicture, nTamanho } )

    cQuery += " SRA.RA_XIDLOCT, "

/*---------------------------------------------------------------*/
    cPicture := GetSx3Cache( 'ZC1_RAZSOC', 'X3_PICTURE' )
    nTamanho := GetSx3Cache( 'ZC1_RAZSOC', 'X3_TAMANHO' )

    aAdd( aCampos, { 'Razão', cPicture, nTamanho } )

    cQuery += " ZC1.ZC1_RAZSOC, "

/*---------------------------------------------------------------*/
    // aAdd( aCampos, { 'Quantidade de TCE/TCA', cPicture, nTamanho } )

/*---------------------------------------------------------------*/
    cPicture := GetSx3Cache( 'RA_XID', 'X3_PICTURE' )
    nTamanho := GetSx3Cache( 'RA_XID', 'X3_TAMANHO' )

    aAdd( aCampos, { 'Código TCE/TCA', cPicture, nTamanho } )

    cQuery += " SRA.RA_XID, "

/*---------------------------------------------------------------*/
    cPicture := GetSx3Cache( 'RA_NOME', 'X3_PICTURE' )
    nTamanho := GetSx3Cache( 'RA_NOME', 'X3_TAMANHO' )

    aAdd( aCampos, { 'Nome', cPicture, nTamanho } )

    cQuery += " SRA.RA_NOME, "

/*---------------------------------------------------------------*/
    cPicture := GetSx3Cache( 'RA_CIC', 'X3_PICTURE' )
    nTamanho := GetSx3Cache( 'RA_CIC', 'X3_TAMANHO' )

    aAdd( aCampos, { 'CPF', cPicture, nTamanho } )

    cQuery += " SRA.RA_CIC, "

/*---------------------------------------------------------------*/
    cPicture := GetSx3Cache( 'RA_ADMISSA', 'X3_PICTURE' )
    nTamanho := GetSx3Cache( 'RA_ADMISSA', 'X3_TAMANHO' )

    aAdd( aCampos, { 'Início da vigência do TCE/TCA', cPicture, nTamanho } )

    aAdd( aField, { 'RA_ADMISSA', 'D' } )

    cQuery += " SRA.RA_ADMISSA, "

/*---------------------------------------------------------------*/
    cPicture := GetSx3Cache( 'RA_DTFIMCT', 'X3_PICTURE' )
    nTamanho := GetSx3Cache( 'RA_DTFIMCT', 'X3_TAMANHO' )

    aAdd( aCampos, { 'Término da vigência do TCE/TCA', cPicture, nTamanho } )

    aAdd( aField, { 'RA_DTFIMCT', 'D' } )

    cQuery += " SRA.RA_DTFIMCT, "

/*---------------------------------------------------------------*/
    cPicture := "@!"
    nTamanho := Len( 'DD/MM/YYYY' )

    aAdd( aCampos, { 'Data Processamento Bolsa-Auxilio', cPicture, nTamanho } )

    //aAdd( aField, { 'RD_DATA', 'D' } )

    cQuery += " 'DD/MM/YYYY', "

/*---------------------------------------------------------------*/
    cPicture := '@!'
    nTamanho := 6

    aAdd( aCampos, { 'Agência', cPicture, nTamanho } )

    cQuery += " LTRIM( RTRIM( RIGHT( SRA.RA_BCDEPSA, 4 ) ) ) + '-' +  SRA.RA_XDIGAG, "

/*---------------------------------------------------------------*/
    cPicture := '@!'
    nTamanho := 20

    aAdd( aCampos, { 'Banco', cPicture, nTamanho } )

    cQuery += " LEFT( SRA.RA_BCDEPSA, 3 ) + '-' + "
    cQuery += " ( SELECT TOP 1 A6_NOME FROM " + RetSqlName("SA6") + " SA6 WHERE D_E_L_E_T_ = '' AND A6_COD = LEFT( SRA.RA_BCDEPSA, 3 ) ), "

/*---------------------------------------------------------------*/
    cPicture := '@!'
    nTamanho := 15

    aAdd( aCampos, { 'Conta Corrente', cPicture, nTamanho } )

    cQuery += " LTRIM( RTRIM( SRA.RA_CTDEPSA ) ) + '-' + LTRIM( RTRIM( SRA.RA_XDIGCON ) ), "

 /*---------------------------------------------------------------*/
    // aAdd( aCampos, { 'Quantidade de Bolsa Auxilio', cPicture, nTamanho } )

/*---------------------------------------------------------------*/
    cPicture := GetSx3Cache( 'RD_VALOR', 'X3_PICTURE' )
    nTamanho := GetSx3Cache( 'RD_VALOR', 'X3_TAMANHO' )

    aAdd( aCampos, { 'Bolsa Auxílio', cPicture, nTamanho } )

    cQuery += " ( SELECT "
    cQuery += " SRD_004.RD_VALOR "
    cQuery += " FROM " + RetSqlName("SRD") + " SRD_004 "
    cQuery += " WHERE SRD_004.RD_FILIAL = SRA.RA_FILIAL "
    cQuery += " AND SRD_004.RD_MAT = SRA.RA_MAT "
    cQuery += " AND SRD_004.RD_PD = '004' "
    cQuery += " AND SRD_004.D_E_L_E_T_ = '' "
    cQuery += " AND SRD_004.RD_DTREF = SRD.RD_DTREF ) RD_VALOR_004, "

/*---------------------------------------------------------------*/
    cPicture := GetSx3Cache( 'RD_VALOR', 'X3_PICTURE' )
    nTamanho := GetSx3Cache( 'RD_VALOR', 'X3_TAMANHO' )

    aAdd( aCampos, { 'Auxilio Transporte', cPicture, nTamanho } )

    cQuery += " ( SELECT "
    cQuery += " SRD_277.RD_VALOR "
    cQuery += " FROM " + RetSqlName("SRD") + " SRD_277 "
    cQuery += " WHERE SRD_277.RD_FILIAL = SRA.RA_FILIAL "
    cQuery += " AND SRD_277.RD_MAT = SRA.RA_MAT "
    cQuery += " AND SRD_277.RD_PD = '277' "
    cQuery += " AND SRD_277.D_E_L_E_T_ = '' "
    cQuery += " AND SRD_277.RD_DTREF = SRD.RD_DTREF ) RD_VALOR_277, "

/*---------------------------------------------------------------*/
    cPicture := GetSx3Cache( 'RD_VALOR', 'X3_PICTURE' )
    nTamanho := GetSx3Cache( 'RD_VALOR', 'X3_TAMANHO' )

    aAdd( aCampos, { 'Imposto de Renda', cPicture, nTamanho } )

    cQuery += " ( SELECT "
    cQuery += " SRD_509.RD_VALOR "
    cQuery += " FROM " + RetSqlName("SRD") + " SRD_509 "
    cQuery += " WHERE SRD_509.RD_FILIAL = SRA.RA_FILIAL "
    cQuery += " AND SRD_509.RD_MAT = SRA.RA_MAT "
    cQuery += " AND SRD_509.RD_PD = '509' "
    cQuery += " AND SRD_509.D_E_L_E_T_ = '' "
    cQuery += " AND SRD_509.RD_DTREF = SRD.RD_DTREF ) RD_VALOR_509, "

/*---------------------------------------------------------------*/
    cPicture := GetSx3Cache( 'RD_VALOR', 'X3_PICTURE' )
    nTamanho := GetSx3Cache( 'RD_VALOR', 'X3_TAMANHO' )

    aAdd( aCampos, { 'Pensão Alimenticia', cPicture, nTamanho } )

    cQuery += " ( SELECT "
    cQuery += " SRD_554.RD_VALOR "
    cQuery += " FROM " + RetSqlName("SRD") + " SRD_554 "
    cQuery += " WHERE SRD_554.RD_FILIAL = SRA.RA_FILIAL "
    cQuery += " AND SRD_554.RD_MAT = SRA.RA_MAT "
    cQuery += " AND SRD_554.RD_PD = '554' "
    cQuery += " AND SRD_554.D_E_L_E_T_ = '' "
    cQuery += " AND SRD_554.RD_DTREF = SRD.RD_DTREF ) RD_VALOR_554, "

/*---------------------------------------------------------------*/
    cPicture := GetSx3Cache( 'RD_VALOR', 'X3_PICTURE' )
    nTamanho := GetSx3Cache( 'RD_VALOR', 'X3_TAMANHO' )

    aAdd( aCampos, { 'Bolsa Auxilio a Pagar', cPicture, nTamanho } )

    cQuery += " ( SELECT "
    cQuery += " SRD_J99.RD_VALOR "
    cQuery += " FROM " + RetSqlName("SRD") + " SRD_J99 "
    cQuery += " WHERE SRD_J99.RD_FILIAL = SRA.RA_FILIAL "
    cQuery += " AND SRD_J99.RD_MAT = SRA.RA_MAT "
    cQuery += " AND SRD_J99.RD_PD = 'J99' "
    cQuery += " AND SRD_J99.D_E_L_E_T_ = '' "
    cQuery += " AND SRD_J99.RD_DTREF = SRD.RD_DTREF ) RD_VALOR_J99, "

/*---------------------------------------------------------------*/
    cPicture := GetSx3Cache( 'RD_DTREF', 'X3_PICTURE' )
    nTamanho := GetSx3Cache( 'RD_DTREF', 'X3_TAMANHO' )

    aAdd( aCampos, { 'Data Pagamento Bolsa-Auxilio', cPicture, nTamanho } )

    aAdd( aField, { 'RD_DTREF', 'D' } )

    cQuery += " SRD.RD_DTREF "

/*---------------------------------------------------------------*/

    cQuery += " FROM " + RetSqlName("SRA") + " SRA "

    cQuery += " INNER JOIN " + RetSqlName("SRD") + " SRD "
    cQuery += " ON SRA.RA_FILIAL = SRD.RD_FILIAL "
    cQuery += " AND SRA.RA_MAT = SRD.RD_MAT "
    cQuery += " AND SRD.RD_SEMANA  = '01' "
    cQuery += " AND SRD.D_E_L_E_T_ = '' "

    cQuery += " INNER JOIN " + RetSqlName("ZC1") + " ZC1 "
    cQuery += " ON  SRA.RA_XIDCONT = ZC1.ZC1_CODIGO "
    cQuery += " AND SRA.RA_XIDLOCT = ZC1.ZC1_LOCCTR "
    cQuery += " AND SRA.D_E_L_E_T_ = '' "

    cQuery += " WHERE SRA.D_E_L_E_T_ = '' "
    cQuery += " AND SRA.RA_XIDCONT BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "' "
    cQuery += " AND SRA.RA_XIDLOCT BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' "
    cQuery += " AND SRA.RA_ADMISSA BETWEEN '" + DtoS( MV_PAR05 ) + "' AND '" + DtoS( MV_PAR06 ) + "' "
    cQuery += " AND SRA.RA_DTFIMCT BETWEEN '" + DtoS( MV_PAR07 ) + "' AND '" + DtoS( MV_PAR08 ) + "' "
    cQuery += " AND LEFT( RA_BCDEPSA, 3 ) BETWEEN '" + MV_PAR09 + "' AND '" + MV_PAR10 + "'
    cQuery += " AND SRD.RD_DTREF BETWEEN '" + Dtos( MV_PAR11 ) + "' AND '" + Dtos( MV_PAR12 ) + "' "


    MsgRun( 'Banco de Dados Processando a Query ...', 'Aguarde ...', { || MPSysOpenQuery( cQuery, cAlias ) } )

    For nX := 1 To Len( aField )

        TcSetField( cAlias, aField[ nX, 1 ], aField[ nX, 2 ] )

    Next nX

return
