#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TOPCONN.CH"

Static lMarkAll := .T.
Static cCampos  := "RA_FILIAL,RA_XATIVO,ZCV_OCORRE,RA_MAT,RA_NOME,RA_CIC,ZCV_DATPGT,RA_XDEATIV,RA_BCDEPSA,RA_XDIGAG,RA_CTDEPSA,RA_XDIGCON,RA_XSTATOC,RQ_XATIVO,ZCV_IDFOL,ZCV_COMPET,RQ_XVALIBC,RQ_NOME,RQ_ORDEM,RQ_SEQUENC,RQ_BCDEPBE,RQ_CTDEPBE,RA_VLDBAN,EB_DESCRI"

/*/{Protheus.doc} CFINA100
	Tela de gerenciamento de inconsistencias bancarias
@author felipe ortega
@since 18/08/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function CFINA100()
    Local oBrw01

    Private cTituloB := "Gerenciamento de inconsistencias - bolsa auxilio"

    FWMsgRun(,{|| U_FFIN1001(@oBrw01) },,"Processando dados, aguarde..." )

    oBrw01:AddLegend("RA_XSTATOC=='1' .AND. (RA_VLDBAN==' ' .OR. RA_VLDBAN=='4')"   , "BR_AMARELO"  , "Dados bancários inválidos", "1")
    oBrw01:AddLegend("EMPTY(RA_BCDEPSA) .AND. (RA_VLDBAN==' ' .OR. RA_VLDBAN=='4')"                       , "BR_VERMELHO" , "Sem dados bancários", "1")
    oBrw01:AddLegend("ZCV_OCORRE!='' .AND. RA_XSTATOC == '3' .AND. (RA_VLDBAN==' ' .OR. RA_VLDBAN=='4')"  , "BR_AZUL"     , "Dados bancários atualizados", "1")
    oBrw01:AddLegend("ZCV_OCORRE!='' .AND. RA_XSTATOC == '2' .AND. (RA_VLDBAN==' ' .OR. RA_VLDBAN=='4')"  , "BR_VERDE"    , "Liberado para geração de CNAB", "1")
    oBrw01:AddLegend("RQ_XATIVO=='N' .AND. RQ_XVALIBC != '1' .AND. (RA_VLDBAN==' ' .OR. RA_VLDBAN=='4')"  , "BR_LARANJA"  , "Ocorrencia no beneficiário", "1")
    oBrw01:AddLegend("RQ_XATIVO=='N' .AND. RQ_XVALIBC == '1' .AND. (RA_VLDBAN==' ' .OR. RA_VLDBAN=='4')"  , "BR_BRANCO"   , "Dados bancários do beneficiário atualizados", "1")    
    oBrw01:AddLegend("RA_VLDBAN=='2' .AND. RA_BCDEPSA!='' "                         , "BR_CINZA"	, "Validação não efetuada", "1")
    oBrw01:AddLegend("RA_VLDBAN == '1'"                                             , "BR_PRETO"    , "Ocorrencia nao encontrada ou banco inexistente", "1")
    oBrw01:AddLegend("RA_XSTATOC=='5'"                                              , "BR_VIOLETA"	, "Devolução de pagamento efetuado", "1") 
    oBrw01:AddLegend("RA_VLDBAN == '3'"                                             , "BR_MARROM"   , "Dados bancarios inconsistentes", "1")

    oBrw01:AddLegend("alltrim(ZCV_OCORRE) != '' .and. RA_VLDBAN == '4'"       , "BR_AZUL"     , "Pagamento", "2")
    oBrw01:AddLegend("alltrim(RQ_NOME) != ''"                                       , "BR_VERDE"    , "Beneficiario", "2")
    oBrw01:AddLegend("alltrim(RQ_NOME) == '' .and. alltrim(ZCV_OCORRE) == ''"       , "BR_BRANCO"   , "Validação bancária", "2")

    oBrw01:Activate()

    ZZZ->(dbCloseArea())
return

/*/{Protheus.doc} FFIN1001
	Monta estrutura do browse
@author felipe ortega
@since 19/08/2020
@version 1.0
@return ${return}, ${return_description}
@param oBrw01, object, descricao
@type function
/*/
user function FFIN1001(oBrw01)
    local aStruct		:= {}
    local cArqTrab		:= ""
    local cAliasQry
    local aColBrowse	:= {}
    local aColumn		:= {}
    local nI
    local xValor
    local aSeek			:= {}
    local aCampos       := strtokarr(cCampos, ",")
    local aCamposBrw    := {"EB_DESCRI", "RA_NOME", "RA_CIC", "ZCV_DATPGT", "RA_BCDEPSA", "RA_XDIGAG", "RA_CTDEPSA", "RA_XDIGCON", "ZCV_IDFOL","ZCV_COMPET", "RA_VLDBAN"}
    local cTipoDesc     := ""

    oBrw01 		:= FwMBrowse():New()

    U_FFIN1002(@cAliasQry)

    for nI := 1 to len(aCampos)

        if alltrim(aCampos[nI]) == "ZCV_COMPET"

            aColumn := getColums(aCampos[nI], '1', "9")

        else

            aColumn := getColums(aCampos[nI], '1')

        endif

        if len(aColumn) > 0

            aAdd(aStruct, aColumn)

        endif

    next

    for nI := 1 to len(aCamposBrw)

        if alltrim(aCamposBrw[nI]) == "ZCV_COMPET"

            aColumn := getColums(aCamposBrw[nI], '2', "9")

        else

            aColumn := getColums(aCamposBrw[nI], '2')

        endif

        if len(aColumn) > 0

            aAdd(aColBrowse, aColumn)

        endif
    next

    cArqTrab := CriaTrab(aStruct, .T.)

    USE &cArqTrab ALIAS ZZZ NEW

    dbSelectArea(cAliasQry)

    (cAliasQry)->(dbGoTop())

    if (cAliasQry)->(!eof())

        DBSELECTAREA("SX3")
        SX3->(DBSETORDER(2))

        while (cAliasQry)->(!eof())

            reclock("ZZZ", .T.)

            for nI := 1 to len(aCampos)

                if aCampos[nI] == "RA_VLDBAN"
                    xValor := (cAliasQry)->(RA_VLDBAN)

                    &("ZZZ->(RA_VLDBAN)") := xValor

                    cTipoDesc := xValor

                    loop
                endif
            
                SX3->(DBSEEK(aCampos[nI]))

                if aScan(aCampos, alltrim(SX3->X3_CAMPO)) > 0

                    if X3USO(SX3->X3_USADO)
                        if SX3->X3_TIPO == "D"

                            if alltrim(aCampos[nI]) == "ZCV_DATPGT" .and. (cAliasQry)->(RA_XSTATOC) == '2'

                                xValor := Stod(&(cAliasQry+"->("+TRIM(SX3->X3_CAMPO)+")"))

                            else

                                xValor := Stod(space(8))

                            endif

                        else

                            xValor := &(cAliasQry+"->("+TRIM(SX3->X3_CAMPO)+")")

                        endif

                        if alltrim(aCampos[nI]) == "ZCV_COMPET"

                            xValor := substr(xValor, 5, 2) + "/" + substr(xValor, 1, 4)

                        endif

                        if alltrim(aCampos[nI]) == "EB_DESCRI"

                            if empty(xValor)
                                if cTipoDesc == '2'

                                    xValor := "Validação banc. não efetuada"

                                else

                                    xValor := "Ocor não encontrada/bco inesis"

                                endif

                                cTipoDesc := ""
                            endif

                        endif

                        &("ZZZ->("+TRIM(SX3->X3_CAMPO)+")") := xValor

                    endif

                endif
            next

            ZZZ->(msUnLock())

            (cAliasQry)->(dbSkip())

        enddo

    endif

    oBrw01:SetAlias("ZZZ")
    oBrw01:SetDescription(cTituloB)
    oBrw01:DisableDetails()

    oBrw01:SetFields(aColBrowse)

    cIndice1 := cArqTrab

    cIndice1 := Left(cIndice1,5)+Right(cIndice1,2)+"A"

    IndRegua( "ZZZ", cIndice1, "RA_MAT",,,"Indice codigo" )

    dbClearIndex()
    ZZZ->(dbSetIndex(cIndice1 + OrdBagExt()))

    //Campos que irão compor o combo de pesquisa na tela principal
    Aadd(aSeek,{"Matricula"   , {{"","C",6,0, "RA_MAT"   ,"@!"}}, 1, .T. } )

    oBrw01:SetSeek(.T.,aSeek)
    oBrw01:SetUseFilter(.T.)
    oBrw01:SetDBFFilter(.T.)
    oBrw01:SetFilterDefault( "" )

    (cAliasQry)->(dbCloseArea())

    oBrw01:SetMenuDef( 'CFINA100' )
    // Ativação da Classe
return

/*/{Protheus.doc} FFIN1002
	Query para carga do browse
@author felipe ortega
@since 19/08/2020
@version 1.0
@return ${return}, ${return_description}
@param cAliasQry, characters, descricao
@type function
/*/
user function FFIN1002(cAliasQry)
    Local cQry 
    local cQryCmp   := cCampos

	cQry 			:= ""
	cAliasQry 		:= GetNextAlias()

    cQryCmp := strTran(cQryCmp, ",RA_VLDBAN", "")

	cQry += "SELECT DISTINCT " + cQryCmp + CRLF 
    //cQry += ", CASE WHEN EB.EB_BANCO IS NULL THEN '1' WHEN RTRIM(LTRIM(EB.EB_BANCO)) = '' THEN '1' ELSE '' END AS RA_VLDBAN " + CRLF
    cQry += ", '4' AS RA_VLDBAN " + CRLF
	cQry += "FROM " + retSqlName("ZCV") + " ZCV " + CRLF
    cQry += "INNER JOIN " + retSqlName("SRA") + " RA ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "LEFT JOIN " + retSqlName("SRQ") + " RQ ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RA.RA_BCDEPSA,1,3) AND ZCV.ZCV_OCORRE LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.D_E_L_E_T_ = ' ' " + CRLF
	cQry += "WHERE ZCV.ZCV_FILIAL = '" + xFilial("ZCV") + "' " + CRLF
	cQry += "AND ZCV.ZCV_OCORRE != '" + space(tamSx3("ZCV_OCORRE")[1]) + "' " + CRLF
    cQry += "AND EB.EB_OCORR = '03' " + CRLF
	cQry += "AND ZCV.D_E_L_E_T_ = ' ' " + CRLF

    cQry += "UNION ALL " + CRLF

    cQry += "SELECT DISTINCT " + cQryCmp + CRLF
    cQry += ", CASE WHEN EB.EB_BANCO IS NULL THEN '1' ELSE '' END AS RA_VLDBAN " + CRLF
	cQry += "FROM " + retSqlName("SRA") + " RA " + CRLF
    cQry += "LEFT JOIN " + retSqlName("ZCV") + " ZCV ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND ZCV.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "LEFT JOIN " + retSqlName("SRQ") + " RQ ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RA.RA_BCDEPSA,1,3) AND RA.RA_XOCOREN LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.D_E_L_E_T_ = ' ' " + CRLF
	cQry += "WHERE RA.RA_FILIAL = '" + xFilial("SRA") + "' " + CRLF
	cQry += "AND RA.RA_XATIVO = 'N' " + CRLF
    cQry += "AND RA.RA_XOCOREN != '          ' " + CRLF
    cQry += "AND EB.EB_OCORR = '03' " + CRLF
	cQry += "AND RA.D_E_L_E_T_ = ' ' " + CRLF

    cQry += "UNION ALL " + CRLF

    cQry += "SELECT DISTINCT " + cQryCmp + CRLF
    cQry += ", CASE WHEN EB.EB_BANCO IS NULL THEN '1' ELSE '' END AS RA_VLDBAN " + CRLF
	cQry += "FROM " + retSqlName("SRQ") + " RQ " + CRLF
    cQry += "INNER JOIN " + retSqlName("SRA") + " RA ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "LEFT JOIN " + retSqlName("ZCV") + " ZCV ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND ZCV.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RQ.RQ_BCDEPBE,1,3) AND RQ.RQ_XOCOREN LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.D_E_L_E_T_ = ' ' " + CRLF
	cQry += "WHERE RQ.RQ_FILIAL = '" + xFilial("SRQ") + "' " + CRLF
    cQry += "AND RQ.RQ_XOCOREN != '          ' " + CRLF
	cQry += "AND RQ.RQ_XATIVO = 'N' " + CRLF
    cQry += "AND EB.EB_OCORR = '03' " + CRLF
	cQry += "AND RQ.D_E_L_E_T_ = ' ' " + CRLF

    cQry += "UNION ALL " + CRLF

    cQry += "SELECT DISTINCT " + cQryCmp + CRLF
    cQry += ", '1' AS RA_VLDBAN  " + CRLF
    cQry += "FROM " + retSqlName("SRA") + " RA  " + CRLF
    cQry += "LEFT JOIN " + retSqlName("ZCV") + " ZCV ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND ZCV.D_E_L_E_T_ = ' '  " + CRLF
    cQry += "LEFT JOIN " + retSqlName("SRQ") + " RQ ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' '  " + CRLF
    cQry += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RA.RA_BCDEPSA,1,3) AND RA.RA_XOCOREN LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.EB_OCORR = '03' AND EB.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "WHERE RA.RA_FILIAL = '" + xFilial("SRA") + "'  " + CRLF
    cQry += "AND RA.RA_XATIVO = 'N'  " + CRLF
    cQry += "AND RA.RA_XOCOREN != '          ' " + CRLF
    cQry += "AND NOT EXISTS(SELECT EB2.EB_BANCO FROM " + retSqlName("SEB") + " EB2 WHERE EB2.EB_BANCO = SUBSTRING(RA.RA_BCDEPSA,1,3) AND RA.RA_XOCOREN LIKE ('%' + RTRIM(LTRIM(EB2.EB_REFBAN)) + '%') AND EB2.D_E_L_E_T_ = ' ' ) " + CRLF
    cQry += "AND RA.D_E_L_E_T_ = ' ' " + CRLF

    cQry += "UNION ALL " + CRLF

    cQry += "SELECT DISTINCT " + cQryCmp + CRLF
    cQry += ", CASE WHEN EB.EB_BANCO IS NULL THEN '2' ELSE '' END AS RA_VLDBAN " + CRLF
	cQry += "FROM " + retSqlName("SRA") + " RA " + CRLF
    cQry += "LEFT JOIN " + retSqlName("ZCV") + " ZCV ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND ZCV.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "LEFT JOIN " + retSqlName("SRQ") + " RQ ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RA.RA_BCDEPSA,1,3) AND RA.RA_XOCOREN LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.D_E_L_E_T_ = ' ' " + CRLF
	cQry += "WHERE RA.RA_FILIAL = '" + xFilial("SRA") + "' " + CRLF
	cQry += "AND RA_BCDEPSA != '' AND RA.RA_CTDEPSA != '' AND RA.RA_XATIVO = 'N' " + CRLF
    cQry += "AND RA.RA_XOCOREN = '' AND RA_XORDPGT = 'N' " + CRLF
    cQry += " " + CRLF
	cQry += "AND RA.D_E_L_E_T_ = ' ' " + CRLF

    cQry += "UNION ALL " + CRLF
    
    cQry += "SELECT DISTINCT " + cQryCmp + CRLF
    cQry += ", '3' AS RA_VLDBAN " + CRLF
	cQry += "FROM " + retSqlName("SRA") + " RA " + CRLF
    cQry += "LEFT JOIN " + retSqlName("ZCV") + " ZCV ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND ZCV.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "LEFT JOIN " + retSqlName("SRQ") + " RQ ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RA.RA_BCDEPSA,1,3) AND RA.RA_XOCOREN LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.D_E_L_E_T_ = ' ' " + CRLF
	cQry += "WHERE RA.RA_FILIAL = '" + xFilial("SRA") + "' " + CRLF
	cQry += "AND RA_BCDEPSA != '' " + CRLF
    cQry += "AND EB.EB_BANCO IS NULL AND RA.RA_CTDEPSA = '' AND RA_XORDPGT = 'N' AND RA.RA_XOCOREN = '          ' " + CRLF
    cQry += "  " + CRLF
	cQry += "AND RA.D_E_L_E_T_ = ' ' " + CRLF

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasQry,.T.,.T.)

	(cAliasQry)->(DbGoTop())
return

/*/{Protheus.doc} MenuDef
	Menus do browse
@author felipe ortega
@since 19/08/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina Title 'Pesquisa'      	         Action 'PesqBrw'        OPERATION 1 ACCESS 0
    ADD OPTION aRotina Title 'Liberar inconsistencia'    Action 'U_FFIN1003'     OPERATION 2 ACCESS 0
    ADD OPTION aRotina Title 'Incons. Benef.'            Action 'U_FFIN1006'     OPERATION 5 ACCESS 0
    ADD OPTION aRotina Title 'Devolução de bolsa'        Action 'U_FFIN1007'     OPERATION 5 ACCESS 0
    ADD OPTION aRotina Title 'Relatorio Conferencia'     Action 'U_CFINR94'      OPERATION 5 ACCESS 0

Return aRotina

/*/{Protheus.doc} getColums
	Retorna estrutura de campo
@author felipe ortega
@since 19/08/2020
@version 1.0
@return ${return}, ${return_description}
@param cCampo, characters, descricao
@param cTipo, characters, descricao
@type function
/*/
static function getColums(cCampo, cTipo, cTamanho)

	local aEstrut	    := {}
    default cTamanho    := ""

	dbSelectArea("SX3")

	SX3->(dbSetOrder(2))

	if SX3->(msSeek(cCampo))

        //ESTRUTURA PARA O CRIA TRAB (A MESMA QUE O DBSTRUCT)
        if cTipo == '1'

            aEstrut := {;
            cCampo,;
            alltrim(SX3->X3_TIPO),;
            if(cTamanho == "", SX3->X3_TAMANHO, val(cTamanho)),;
            SX3->X3_DECIMAL;
            }

        //ESTRUTURA PARA CAMPOS QUE SERÃO EXIBIDOS NO BROWSE
        else

            aEstrut := {;
            alltrim(SX3->X3_TITULO),;
            cCampo,;
            alltrim(SX3->X3_TIPO),;
            iif(cTamanho == "", alltrim(SX3->X3_TAMANHO), cTamanho),;
            alltrim(SX3->X3_DECIMAL),;
            alltrim(SX3->X3_PICTURE);
            }

        endif
    else

        //ESTRUTURA PARA O CRIA TRAB (A MESMA QUE O DBSTRUCT)
        if cTipo == '1'
            if alltrim(cCampo) == "RA_VLDBAN"
                aEstrut := {;
                cCampo,;
                "C",;
                1,;
                0;
                }
            endif
        //ESTRUTURA PARA CAMPOS QUE SERÃO EXIBIDOS NO BROWSE
        else
            if alltrim(cCampo) == "RA_VLDBAN"
                aEstrut := {;
                "Vld Banco",;
                cCampo,;
                "C",;
                "1",;
                "0",;
                "";
                }
            endif
        endif

	endif

return aEstrut

/*/{Protheus.doc} FFIN1003
	Monta tela para selecionar liberações
@author felipe ortega
@since 19/08/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
user function FFIN1003()

    local lOk	        := .F.
    local aTitSt        := {}
    local aAdvSize      := {}
    local oOk	        := LoadBitmap( GetResources(), "LBTIK" )	//CHECKED    //LBOK  //LBTIK
    local oNo	        := LoadBitmap( GetResources(), "LBNO" ) 	//UNCHECKED  //LBNO
    local cAliasQry
    local nCnta
    local dGetRef   := dDataBase
    local aCombo	:= {"Pagamento", "Validacao bancaria", "Beneficiario"}
    local aParamBox := {}
    Private nTipPro := 0 
    

    aAdd(aParamBox,{3,"Informe o tipo para liberação","Pagamento",aCombo,90,"",.F.})

    if ParamBox(aParamBox,"Parâmetros...")

        nTipPro := MV_PAR01

        U_FFIN1004(@cAliasQry)

        if (cAliasQry)->(!eof())
            while (cAliasQry)->(!eof())
                if (cAliasQry)->RQ_XATIVO == "N"

                    Aadd(aTitSt,{.T.,;
                                (cAliasQry)->RA_MAT,;
                                (cAliasQry)->RQ_NOME,;
                                (cAliasQry)->RA_BCDEPSA,;
                                (cAliasQry)->RA_CTDEPSA,;
                                "Sim",;
                                (cAliasQry)->RQ_ORDEM,;
                                (cAliasQry)->RQ_SEQUENC;
                                })

                else

                    Aadd(aTitSt,{.T.,;
                                (cAliasQry)->RA_MAT,;
                                (cAliasQry)->RA_NOME,;
                                (cAliasQry)->RA_BCDEPSA,;
                                (cAliasQry)->RA_CTDEPSA,;
                                "Nao",;
                                "",;
                                "",;
                                (cAliasQry)->ZCV_IDFOL,;
                                (cAliasQry)->ZCV_COMPET;
                                })

                endif
                (cAliasQry)->(dbSkip())
            enddo

            aAdvSize:= MsAdvSize()
            DEFINE MSDIALOG oDlg TITLE "Liberação para pagamento" FROM aAdvSize[7],aAdvSize[1] TO aAdvSize[6],aAdvSize[5] OF oMainWnd PIXEL STYLE DS_SYSMODAL
            
            EnchoiceBar(oDlg,{|| FFIN1005(@oDlg, @lOk, @dGetRef, "Data de pagamento") },{|| oDlg:End()},,)
            
            @ 08,10 SAY "Selecione para liberar ocorrência." SIZE 200,008 PIXEL OF oDlg
            @ 20,10 LISTBOX oLbx;
            FIELDS HEADER " ", RetTitle("RA_MAT"),RetTitle("RA_NOME"),RetTitle("RA_BCDEPSA"),RetTitle("RA_CTDEPSA"), "Beneficiario", RetTitle("RQ_ORDEM"), RetTitle("RQ_SEQUENC") SIZE 350,085 OF oDlg PIXEL ON dblClick(aTitSt[oLbx:nAt,1]:=!aTitSt[oLbx:nAt,1])
            
            oLbx:SetArray( aTitSt )
            oLbx:bLine := {|| {Iif(aTitSt[oLbx:nAt,1],oOk,oNo),;
                                aTitSt[oLbx:nAt,2],;
                                aTitSt[oLbx:nAt,3],;
                                aTitSt[oLbx:nAt,4],;
                                aTitSt[oLbx:nAt,5],;
                                aTitSt[oLbx:nAt,6],;
                                aTitSt[oLbx:nAt,7],;
                                aTitSt[oLbx:nAt,8]}}													
            oLbx:Align:= CONTROL_ALIGN_ALLCLIENT
            ACTIVATE MSDIALOG oDlg CENTER

            if lOk

                dbSelectArea("SRA")
                SRA->(dbSetOrder(1))

                dbSelectArea("ZZZ")
                ZZZ->(dbSetOrder(1))

                dbSelectArea("ZCV")
                ZCV->(dbSetOrder(1))

                dbSelectArea("SRQ")
                SRQ->(dbSetOrder(1))

                For nCnta:=1 to Len(aTitSt)
                    IF aTitSt[nCnta][1]

                        begin transaction 

                            if SRA->(msSeek(xFilial("SRA") + alltrim(aTitSt[nCnta][2])))
                                RECLOCK("SRA",.F.)
                                    SRA->RA_XSTATOC := '2'
                                SRA->(MSUNLOCK())

                                ZZZ->(msSeek(alltrim(aTitSt[nCnta][2])))

                                reclock("ZZZ", .F.)

                                ZZZ->RA_XSTATOC := '2'
                                ZZZ->ZCV_DATPGT  := dGetRef

                                ZZZ->(msUnLock())

                                if aTitSt[nCnta][6] == "Sim"

                                    SRQ->(msSeek(xFilial("SRQ") + padr(aTitSt[nCnta][2], tamsx3("RQ_MAT")[1]) + padr(aTitSt[nCnta][7], tamsx3("RQ_ORDEM")[1]) + aTitSt[nCnta][8]))

                                    reclock("SRQ", .F.)

                                    SRQ->RQ_XDTEFET := dGetRef
                                    SRQ->RQ_XSTATOC := "2"

                                    SRQ->(msUnLock())

                                else

                                    /*ZCV->(msSeek(xFilial("ZCV") + alltrim(aTitSt[nCnta][2])))

                                    reclock("ZCV", .F.)

                                    ZCV->ZCV_DATPGT := dGetRef

                                    ZCV->(msUnLock())*/

                                    IF TCSQLEXEC("UPDATE "+RETSQLNAME("ZCV") + " SET ZCV_STATUS='2',ZCV_DATPGT = '" + dtos(dGetRef) +;
                                                "' WHERE ZCV_FILIAL='"  + xFilial("ZCV") +"' AND ZCV_MAT ='" + alltrim(aTitSt[nCnta][2]) + "' AND ZCV_IDFOL = '" + alltrim(aTitSt[nCnta][9]) + "' AND ZCV_COMPET = '" + alltrim(aTitSt[nCnta][10]) + "' AND D_E_L_E_T_=''") < 0
                                        MSGALERT(TCSQLERROR())
                                    ENDIF 

                                endif
                            ENDIF	  

                        end transaction              
                    Endif
                Next

                //Realiza novo calculo da bolsa
                If nTipPro == 1
                    U_CJOBK15(dGetRef)
                Endif                

            endif
        else

            msgInfo("Nenhum registro apto a ser liberado")

        endif

    endif

return

user function FFIN1007()

    local lOk	        := .F.
    local lMsg          := .f.

    local aTitSt        := {}
    local aAdvSize      := {}
    local aRegistro     := {}

    local oOk	        := LoadBitmap( GetResources(), "LBTIK" )	//CHECKED    //LBOK  //LBTIK
    local oNo	        := LoadBitmap( GetResources(), "LBNO" ) 	//UNCHECKED  //LBNO

    local cAliasQry
    local cQry          := ""
    local cQryCmp       := cCampos
    local cFornece      := ""
    local cContrato     := ""

    local nI

    local dGetRef       := dDataBase

    cQryCmp := strTran(cQryCmp, ",RA_VLDBAN", "")

    cAliasQry := GetNextAlias()

    cQry += "SELECT DISTINCT ZC0.ZC0_CODIGO, ZCV.ZCV_IDCNT, ZC0.ZC0_NUMDOC, ZCV.ZCV_VALOR , " + cQryCmp + CRLF 
    cQry += ", CASE WHEN EB.EB_BANCO IS NULL THEN '1' WHEN RTRIM(LTRIM(EB.EB_BANCO)) = '' THEN '1' ELSE '' END AS RA_VLDBAN, RA.R_E_C_N_O_ RECNO " + CRLF
	cQry += "FROM " + retSqlName("ZCV") + " ZCV " + CRLF
    cQry += "INNER JOIN " + retSqlName("SRA") + " RA ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "LEFT JOIN " + retSqlName("SRQ") + " RQ ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RA.RA_BCDEPSA,1,3) AND ZCV.ZCV_OCORRE LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "INNER JOIN " + retSqlName("ZC0") + " ZC0 ON ZC0.ZC0_CODIGO = ZCV.ZCV_IDCNT AND ZC0.D_E_L_E_T_ = ' ' " + CRLF
	cQry += "WHERE ZCV.ZCV_FILIAL = '" + xFilial("ZCV") + "' " + CRLF
	cQry += "AND ZCV.ZCV_OCORRE != '" + space(tamSx3("ZCV_OCORRE")[1]) + "' " + CRLF
    cQry += "AND EB.EB_OCORR = '03' " + CRLF
    cQry += "AND RA_XSTATOC = '1' " + CRLF
	cQry += "AND ZCV.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "ORDER BY ZCV.ZCV_IDCNT" + CRLF

    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasQry,.T.,.T.)

    if (cAliasQry)->(!eof())
        while (cAliasQry)->(!eof())

            Aadd(aTitSt,{.T.,;
                        (cAliasQry)->RA_MAT,;
                        (cAliasQry)->RA_NOME,;
                        (cAliasQry)->RA_BCDEPSA,;
                        (cAliasQry)->RA_CTDEPSA,;
                        (cAliasQry)->ZC0_NUMDOC,;
                        (cAliasQry)->ZCV_VALOR,;
                        (cAliasQry)->ZC0_CODIGO,;
                        (cAliasQry)->RECNO,;
                        })

            (cAliasQry)->(dbSkip())
        enddo

        aAdvSize:= MsAdvSize()
        DEFINE MSDIALOG oDlg TITLE "Devolução de pagamento" FROM aAdvSize[7],aAdvSize[1] TO aAdvSize[6],aAdvSize[5] OF oMainWnd PIXEL STYLE DS_SYSMODAL
        
        EnchoiceBar(oDlg,{|| FFIN1005(@oDlg, @lOk, @dGetRef, "Data da devolução") },{|| oDlg:End()},,)
        
        @ 08,10 SAY "Selecione os pagamentos para devolução." SIZE 200,008 PIXEL OF oDlg
        @ 20,10 LISTBOX oLbx;
        FIELDS HEADER " ", RetTitle("RA_MAT"),RetTitle("RA_NOME"),RetTitle("RA_BCDEPSA"),RetTitle("RA_CTDEPSA"),RetTitle("ZC0_NUMDOC"),RetTitle("ZCV_VALOR"), RetTitle("ZC0_CODIGO") SIZE 350,085 OF oDlg PIXEL ON dblClick(aTitSt[oLbx:nAt,1]:=!aTitSt[oLbx:nAt,1])
        
        oLbx:SetArray( aTitSt )
        oLbx:bLine := {|| {Iif(aTitSt[oLbx:nAt,1],oOk,oNo),;
                            aTitSt[oLbx:nAt,2],;
                            aTitSt[oLbx:nAt,3],;
                            aTitSt[oLbx:nAt,4],;
                            aTitSt[oLbx:nAt,5],;
                            aTitSt[oLbx:nAt,6],;
                            aTitSt[oLbx:nAt,7],;
                            aTitSt[oLbx:nAt,8]}}													
        oLbx:Align:= CONTROL_ALIGN_ALLCLIENT
        ACTIVATE MSDIALOG oDlg CENTER

        if lOk

            for nI := 1 to len(aTitSt)

                if aTitSt[nI][1]

                    if alltrim(cFornece) != alltrim(aTitSt[nI][6])

                        if !empty(cFornece)
                        
                            if FFIN1008(aRegistro, cFornece, dGetRef, cContrato)

                                dbSelectArea("SRA")

                                for nJ := 1 to len(aRegistro)

                                    SRA->(dbGoTo(aRegistro[nJ, 4]))

                                    if SRA->(recno()) == aRegistro[nJ, 4]

                                        reclock("SRA", .F.)

                                        SRA->RA_XSTATOC := '5'

                                        SRA->(msunlock())

                                        ZZZ->(dbSetOrder(1))

                                        ZZZ->(msSeek(SRA->RA_MAT))

                                        reclock("ZZZ", .F.)

                                        ZZZ->RA_XSTATOC := '5'

                                        ZZZ->(msunlock())

                                        lMsg := .t.

                                    endif

                                next

                            endif

                        endif

                        cFornece := alltrim(aTitSt[nI][6])

                        cContrato := alltrim(aTitSt[nI][8])

                        aRegistro := {}

                    endif

                    aAdd(aRegistro, {aTitSt[nI][2], aTitSt[nI][7], aTitSt[nI][7], aTitSt[nI][9]})

                endif

            next

            if FFIN1008(aRegistro, cFornece, dGetRef, cContrato) //processa ultimo registro

                dbSelectArea("SRA")

                for nJ := 1 to len(aRegistro)

                    SRA->(dbGoTo(aRegistro[nJ, 4]))

                    if SRA->(recno()) == aRegistro[nJ, 4]

                        reclock("SRA", .F.)

                        SRA->RA_XSTATOC := '5'

                        SRA->(msunlock())

                        ZZZ->(dbSetOrder(1))

                        ZZZ->(msSeek(SRA->RA_MAT))

                        reclock("ZZZ", .F.)

                        ZZZ->RA_XSTATOC := '5'

                        ZZZ->(msunlock())

                        lMsg := .t.

                    endif

                next

            endif

        endif
    else

        msgInfo("Nenhum registro apto a ser devolvido")

    endif

    if lMsg

        msgInfo("Processo de devolução iniciado com sucesso")

    endif

return

/*/{Protheus.doc} FFIN1004
	Query para tela de liberações
@author felipe ortega
@since 19/08/2020
@version 1.0
@return ${return}, ${return_description}
@param cAliasQry, characters, descricao
@type function
/*/
user function FFIN1004(cAliasQry)
    Local cQry 
    local cQryCmp   := cCampos

	cQry 			:= ""
	cAliasQry 		:= GetNextAlias()

    cQryCmp := strTran(cQryCmp, ",RA_VLDBAN", "")

    if nTipPro == 1

        cQry += "SELECT DISTINCT " + cQryCmp + CRLF
        cQry += "FROM " + retSqlName("ZCV") + " ZCV " + CRLF
        cQry += "INNER JOIN " + retSqlName("SRA") + " RA ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
        cQry += "LEFT JOIN " + retSqlName("SRQ") + " RQ ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
        cQry += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RA.RA_BCDEPSA,1,3) AND ZCV.ZCV_OCORRE LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.D_E_L_E_T_ = ' ' " + CRLF
        cQry += "WHERE ZCV.ZCV_FILIAL = '" + xFilial("ZCV") + "' " + CRLF
        cQry += "AND ZCV.ZCV_OCORRE != '" + space(tamSx3("ZCV_OCORRE")[1]) + "' " + CRLF
        cQry += "AND RA.RA_XSTATOC = '3' " + CRLF
        cQry += "AND ZCV.D_E_L_E_T_ = ' ' " + CRLF

    elseif nTipPro == 3
        //cQry += "UNION ALL" + CRLF
        cQry += "SELECT DISTINCT " + cQryCmp + CRLF
        cQry += "FROM " + retSqlName("SRQ") + " RQ " + CRLF
        cQry += "INNER JOIN " + retSqlName("SRA") + " RA ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
        cQry += "LEFT JOIN " + retSqlName("ZCV") + " ZCV ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
        cQry += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RQ.RQ_BCDEPBE,1,3) AND RQ.RQ_XOCOREN LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.D_E_L_E_T_ = ' ' " + CRLF
        cQry += "WHERE RQ.RQ_FILIAL = '" + xFilial("SRQ") + "' " + CRLF
        cQry += "AND RQ.RQ_XVALIBC = '1' " + CRLF
        cQry += "AND RQ.RQ_XATIVO = 'N' " + CRLF
        cQry += "AND RQ.D_E_L_E_T_ = ' ' " + CRLF

    else
        cQry += "SELECT DISTINCT " + cQryCmp + CRLF
        cQry += "FROM " + retSqlName("SRA") + " RA " + CRLF
        cQry += "LEFT JOIN " + retSqlName("SRQ") + " RQ ON RA.RA_FILIAL = RQ.RQ_FILIAL AND RA.RA_MAT = RQ.RQ_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
        cQry += "LEFT JOIN " + retSqlName("ZCV") + " ZCV ON RA.RA_FILIAL = ZCV.ZCV_FILIAL AND RA.RA_MAT = ZCV.ZCV_MAT AND RA.D_E_L_E_T_ = ' ' " + CRLF
        cQry += "LEFT JOIN " + retSqlName("SEB") + " EB ON EB.EB_BANCO = SUBSTRING(RQ.RQ_BCDEPBE,1,3) AND RQ.RQ_XOCOREN LIKE ('%' + RTRIM(LTRIM(EB.EB_REFBAN)) + '%') AND EB.D_E_L_E_T_ = ' ' " + CRLF
        cQry += "WHERE RA.RA_FILIAL = '" + xFilial("SRA") + "' " + CRLF
        cQry += "AND RQ.RQ_XVALIBC = '" + space(tamSx3("RQ_XVALIBC")[1]) + "' " + CRLF
        cQry += "AND RA.RA_XSTATOC = '3' " + CRLF
        cQry += "AND ZCV.ZCV_OCORRE = '" + space(tamSx3("ZCV_OCORRE")[1]) + "' " + CRLF
        cQry += "AND RA.D_E_L_E_T_ = ' ' " + CRLF
    endif

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasQry,.T.,.T.)

	(cAliasQry)->(DbGoTop())
return

/*/{Protheus.doc} FFIN1005
	Monta tela de seleção de data de pagamento
@author felipe ortega
@since 19/08/2020
@version 1.0
@return ${return}, ${return_description}
@param oDlg, object, descricao
@param lOk, logical, descricao
@type function
/*/
static function FFIN1005(oDlg, lOk, dGetRef, cLblData)
    local lProCNAB      := .f.
    local oDlgData

    DEFINE MSDIALOG oDlgData TITLE "Pagamento inconsistencias " From 000,000 to 085,280 COLORS 0, 16777215 PIXEL

    @ 006, 009 SAY oSay PROMPT cLblData SIZE 073,007 OF oDlgData COLORS 0, 16777215 PIXEL
    @ 005,084 MSGET oGet VAR dGetRef SIZE 045,011 OF oDlgData COLORS 0, 16777215 PIXEL
    @ 022,093 BUTTON oButtonOK PROMPT "OK" SIZE 034,013 OF oDlgData PIXEL Action(lProCNAB:= .T., oDlgData:End())
    @ 022,054 BUTTON oButtonCancel PROMPT "Cancela" SIZE 034,013 OF oDlgData PIXEL Action(lProCNAB:= .F., oDlgData:End())

    ACTIVATE MSDIALOG oDlgData CENTERED

    if lProCNAB
        if !empty(Dtos(dGetRef))
            lOk := .t.
            oDlg:end()
        else
            msgAlert("Obrigatorio digitar a data de pagamento")
        endif
    endif
return

/*/{Protheus.doc} FFIN1006
	Carrega tela de inconsistencia do beneficiario
@author felipe ortega
@since 28/08/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
user function FFIN1006()

    local aButtons		:= {}
    local aHeadAux		:= {} 
	local aColsAux		:= {}
    local aYesFields	

    local oDlg
    local oPnlbot
    local oPnlbot2
    local oGetD01

    local nUsado		:= 0  
    local nLin
    local nCnt

    local cQry          := ""
    local cTab          := GetNextAlias()
    local cAliasAprov   := "SRQ"

    aYesFields	:= {"RQ_MAT","RQ_NOME","RQ_SEQUENC","RQ_CIC","RQ_XDEATIV"} 

    aHeadAux := u_QualCPO( cAliasAprov , aYesFields, {} )

    cQry    += "SELECT RQ_MAT, RQ_NOME, RQ_SEQUENC, RQ_CIC, RQ_XDEATIV " + CRLF
    cQry    += "FROM " + retSqlName("SRQ") + CRLF
    cQry    += "WHERE " + CRLF
    cQry    += "RQ_MAT = '" + ZZZ->RA_MAT + "' " + CRLF
    cQry    += "AND D_E_L_E_T_ = ' '"

    TcQuery cQry NEW ALIAS (cTab)

	(cTab)->(dbSelectArea((cTab)))                    
	(cTab)->(dbGoTop())                               	
	While (cTab)->(!Eof())        		
		nUsado := len(aHeadAux)
		AADD(aColsAux,Array(nUsado+2))
		nLin := len(aColsAux)   	       				
		For nCnt:= 1 TO nUsado  
			If aHeadAux[nCnt][8] == 'D' 

				aColsAux[nLin][nCnt]:= DtoC(StoD((cTab)->&(aHeadAux[nCnt][2])))

			Else

				aColsAux[nLin][nCnt]:= (cTab)->&(aHeadAux[nCnt][2])

			EndIf					
		NEXT nCntc    
		aColsAux[nLin][nUsado+2]:= .F.					    	   	   	   
		(cTab)->(dbSkip())	
	End  
	(cTab)->(dbCloseArea()) 

    IF !EMPTY(aColsAux)	

        DEFINE MSDIALOG oDlg TITLE "" FROM 0,0 TO 300,650 PIXEL  

        EnchoiceBar(oDlg,{|| oDlg:End() },{|| oDlg:End()},,aButtons)

        oPnlbot:= TPanel():New(0,0 ,'' ,oDlg , ,.T. ,.T. ,,,0,30,.F.,.F. )
        oPnlbot:Align := CONTROL_ALIGN_BOTTOM	

        oPnlbot2:= TPanel():New(0,0 ,'' ,oDlg , ,.T. ,.T. ,,,0,10,.T.,.T. )
        oPnlbot2:Align := CONTROL_ALIGN_BOTTOM	

        oGetD01:= MsNewGetDados():New(1,1,1,1,0,"AllwaysTrue","AllwaysTrue",,,,999,"AllwaysTrue()",,,oDlg,aHeadAux,aColsAux)

        oGetD01:oBrowse:Align	:= CONTROL_ALIGN_ALLCLIENT

        ACTIVATE MSDIALOG oDlg CENTERED 

    else

        msgAlert("Sem inconsistencias no Beneficiario")

    endif

return

static function FFIN1008(aRegistro, cCgc, dGetRef, cContrato)
    local nI
    local nTotal    := 0

    local lFornece  := .t.
    local lRet      := .t.

    local cLgRede   := ALLTRIM(UsrRetName(RetCodUsr()))
    local cTab
    local cFornece
    local cLoja

    if cLgRede == "Administrador" .or. cLgRede == "Siga"
        cLgRede := "ciee"
    endif

    cTab:= GetNextAlias()

	BeginSql Alias cTab
		SELECT ZAA_MAT,ZAA_NOME,ZAA_CC,CTD_DESC01 FROM %TABLE:ZAA% ZAA
		INNER JOIN %TABLE:CTD% CTD ON CTD_FILIAL=%EXP:XFILIAL("CTD")%
			AND CTD_ITEM=ZAA_CC
			AND CTD.D_E_L_E_T_=''
		WHERE (LTRIM(RTRIM(ZAA_LGREDE))=%EXP:cLgRede% OR RTRIM(ZAA_MAT)=%EXP:LEFT(cLgRede,5)%)
		AND ZAA.D_E_L_E_T_=''
	EndSql

    if (cTab)->(!eof())

        dbSelectArea("SA2")

        SA2->(dbSetOrder(3))

        if !SA2->(msSeek(xFilial("SA2") + cCgc ))
            lFornece := FFIN1009(cCgc, @cFornece, @cLoja, @cContrato)
        else
            cFornece := SA2->A2_COD
            cLoja    := SA2->A2_LOJA
        endif

        if lFornece

            for nI := 1 to len(aRegistro)

                nTotal += aRegistro[nI, 2]

            next

            dbSelectArea("ZPN")

            reclock("ZPN", .T.)

            ZPN->ZPN_FILIAL     := xFilial("ZPN")
            ZPN->ZPN_DTSOL      := dDataBase
            ZPN->ZPN_DTVENC     := dGetRef
            ZPN->ZPN_FORNECE    := alltrim(cFornece)
            ZPN->ZPN_DSCFOR     := alltrim(SA2->A2_NOME)
            ZPN->ZPN_CR         := ALLTRIM((cTab)->ZAA_CC)
            ZPN->ZPN_CRDESC     := ALLTRIM((cTab)->CTD_DESC01)
            ZPN->ZPN_NOMESL     := ALLTRIM((cTab)->ZAA_NOME)
            ZPN->ZPN_NUMSOL     := ALLTRIM((cTab)->ZAA_MAT)
            ZPN->ZPN_DTEMI      := dDataBase
            ZPN->ZPN_HIST       := "Devolução de bolsa auxilio"
            ZPN->ZPN_LOJA       := alltrim(cLoja)
            ZPN->ZPN_STATUS     := '7'
            ZPN->ZPN_TOTAL      := nTotal

            ZPN->(msUnLock())

        else

            lRet := .f.

        endif

    else
        
        lRet := .f.

    endif

return lRet

static function FFIN1009(cCgc, cFornece, cLoja, cContrato)
    local lRet      := .t.
    
    local aErro

    local cErro
    local cQry      := ""
    local cAliasQry := GetNextAlias()

    local nI

    Private lMsErroAuto     := .F.
    Private lMsHelpAuto	    := .F.
    Private lAutoErrNoFile  := .T.
    Private lContaZC2       := .f. //VARIAVEL PRIVATE USADA PARA VALIDAR SE CADASTRA BANCO VIA AVISO NO FONTE MA020TOK

    dbSelectArea("ZC2")

    ZC2->(dbSetOrder(2))

    if ZC2->(msSeek(xFilial("ZC2") + cContrato))
        if alltrim(ZC2->ZC2_BCODEV) != '' .and. alltrim(ZC2->ZC2_CONTA) != ''
            lContaZC2 := .t.
        endif
    endif

    cQry += "SELECT ZC1.* " + CRLF
    cQry += "FROM " + retSqlName("ZC1") + " ZC1 " + CRLF
    cQry += "WHERE ZC1.ZC1_FILIAL = '" + xFilial("ZC1") + "' " + CRLF
    cQry += "AND ZC1.ZC1_DOCLOC = '" + cCgc + "' " + CRLF
    cQry += "AND ZC1.D_E_L_E_T_ = ' ' " + CRLF

    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasQry,.T.,.T.)

    if (cAliasQry)->(!eof())

        aFornecedor :={ {"A2_NOME"		,alltrim((cAliasQry)->ZC1_RAZSOC)	,Nil},;      
                        {"A2_CEP"		,alltrim((cAliasQry)->ZC1_CEPLOC)	,Nil},;
                        {"A2_END"		,alltrim((cAliasQry)->ZC1_LOGLOC) + " " + alltrim((cAliasQry)->ZC1_ENDLOC) + " " + alltrim((cAliasQry)->ZC1_NUMLOC) ,Nil},;
                        {"A2_EST"		,alltrim((cAliasQry)->ZC1_ESTLOC)	,Nil},;
                        {"A2_COD_MUN"	,alltrim((cAliasQry)->ZC1_CMUNLO)	,Nil},;
                        {"A2_MUN"		,alltrim((cAliasQry)->ZC1_CIDLOC)	,Nil},;
                        {"A2_TIPO"		,'J'         	    	            ,Nil},;
                        {"A2_CGC"	    ,alltrim((cAliasQry)->ZC1_DOCLOCA1_CGC)  	    ,Nil},;
                        {"A2_XFAVRES"   ,"S"                                ,Nil},;
                        {"A2_XSOLRES"   ,"S"                                ,Nil},;
                        {"A2_XINTEG"	,"N"                                ,Nil},;
                        {"A2_XTPFOR"	,"9"                                ,Nil}}

        begin transaction

            MSExecAuto({|x,y| MATA020(x,y)},aFornecedor,3)

            IF lMsErroAuto
                aErro := GetAutoGRLog()
                cErro := ""
                For nI := 1 to Len(aErro)
                    cErro += aErro[nI] + CRLF
                Next nI
                U_uCONOUT(cErro)

                lRet := .f.
            else

                dbSelectArea("SZK")

                SZK->(dbSetOrder(5))

                cFornece    := SA2->A2_COD
                cLoja       := SA2->A2_LOJA

                if !SZK->(msSeek(xFilial("SZK") + cFornece + cLoja))

                    if lContaZC2

                        reclock("SZK", .T.)

                        SZK->ZK_FILIAL      := xFilial("SZK")
                        SZK->ZK_FORNECE     := cFornece
                        SZK->ZK_LOJA        := cLoja
                        SZK->ZK_NOME        := alltrim(SA2->A2_NOME)
                        SZK->ZK_BANCO       := alltrim(ZC2->ZC2_BCODEV)
                        SZK->ZK_NOMBCO      := ""
                        SZK->ZK_AGENCIA     := alltrim(ZC2->ZC2_AGEDEV)
                        SZK->ZK_DVAG        := alltrim(ZC2->ZC2_AGDIGD)
                        SZK->ZK_TIPO        := alltrim(ZC2->ZC2_CCTIPO)
                        if alltrim(ZC2->ZC2_CCTIPO) == '1'
                            SZK->ZK_NUMCON      := alltrim(ZC2->ZC2_CONTA)
                            SZK->ZK_NROPOP      := ""
                        else
                            SZK->ZK_NROPOP      := alltrim(ZC2->ZC2_CONTA)
                            SZK->ZK_NUMCON      := ""
                        endif
                        SZK->ZK_STATUS      := 'A'
                        SZK->ZK_E_LIMIT     := 0
                        SZK->ZK_E_SLDIA     := 0
                        SZK->ZK_E_SLDAT     := 0
                        SZK->ZK_E_SLDPR     := 0
                        SZK->ZK_DIGCONT     := 'N'
                        SZK->ZK_PRINCIP     := '1'

                        SZK->(msUnLock())

                    endif

                endif

            Endif

        end transaction
    else
        msgAlert("Não foi possivel gerar o fornecedor pois não há cliente cadastrado com este CNPJ")
        lRet := .f.
    endif
return lRet
