#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} CJOBK06
Rotina de provisionamento dos contratos e locais de contrato
@author carlos.henrique
@since 06/11/2019
@version undefined
@type User function
/*/
User Function CJOBK06()
    Local _lJob		:= GetRemoteType() == -1 // Verifica se é job
    Local _cProcesso:= "CJOBK06JOB"
    Local _lProvis  := .F.
    
    Private lGravado:= .F.

    Begin Sequence

        If _lJob
            U_CJBK06LOG(1,"["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK06] Iniciando processamento via schedule.")
            U_CJBK06LOG(1,"Empresa:" + CEMPANT )
            U_CJBK06LOG(1,"Filial :" + CFILANT )
            U_CJBK06LOG(1,"Data   :" + DTOC(dDataBase) )
            _lProvis  := .T.
        else
            _lProvis:= MSGYESNO("Confirma o provisionamento ?")
        Endif

        if _lProvis

            If !LockByName(_cProcesso,.T.,.T.)
                If _lJob
                    U_CJBK06LOG(1,"["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][ "+_cProcesso+" ] Já existe um processamento em execução, aguarde!")
                ELSE
                    MSGINFO("Já existe um processamento em execução, aguarde! "+CRLF+" Processo: "+_cProcesso)
                Endif
                Break
            Endif

            If !_lJob

                //Realiza o provisionamento
                //FWMsgRun(,{|| CJBK06PR(_lJob) },,"Processando provisionamento de BA e CI, aguarde...")
               MsgRun ( "Processando provisionamento de BA e CI, aguarde...", '', { || CJBK06PR(_lJob) } )    


                //Realiza contabilização
                MsgRun ( "Contabilizando provisionamentos de CI", '', { || ProcCTB() } )
                
                If lGravado
                
                	msginfo("Provisionamento concluído com sucesso!")
                Else
                	msginfo("Provisionamento não realizado!")
                EndIf

            Else

                //Realiza o provisionamento
                CJBK06PR(_lJob)

                U_CJBK06LOG(1,"Provisionamento concluído com sucesso!")

            Endif

            UnLockByName(_cProcesso,.T.,.T.)
        ENDIF

    End Sequence

Return Nil

/*/{Protheus.doc} CJBK06PR
Rotina de processamento
@author carlos.henrique
@since 14/11/2019
@version undefined
@type function
/*/
STATIC FUNCTION CJBK06PR(_lJob)
    Local _cAliasRc0:= GetNextAlias()
    Local _cBcoProv := ALLTRIM(GetMv("CI_BCPRBA",.F.,"237"))  // Banco de provisionamento de BA
    Local _cAliasZc1:= ""
    Local _cAliasSra:= ""
    Local _nTotTit  := 0
    Local _dDtVenc  := ctod("")
    Local _nCnt     := 0
    Local _dDtIni   := FirstDate(date())
    Local nVlrCnt   := 0
    Local nX        := 0
    Local oJson     := nil
        
    Private cCnpjBB := ALLTRIM(SuperGetMV("CI_CNPJBB",.T.,"")) //Cnpj base da banco do brasil
    Private cCnpjCX := ALLTRIM(SuperGetMV("CI_CNPJCX",.T.,"")) //Cnpj base da caixa

    dbselectarea("RC0")
    dbselectarea("ZC0")
    dbselectarea("ZC1")
    dbselectarea("ZC4")
    dbselectarea("ZCN")

//Realiza provisionamento de BA apenas para contrato centralizado
    BeginSql Alias _cAliasRc0
    SELECT RC0.R_E_C_N_O_ AS RECRC0           
    FROM %TABLE:RC0% RC0	
    WHERE RC0_FILIAL=%xfilial:RC0%
        AND RC0_XCODBA=%Exp:_cBcoProv%    
        AND RC0.D_E_L_E_T_=''	
    EndSql

//GETLastQuery()[2]
    IF (_cAliasRc0)->(!Eof())

        RC0->(Dbgoto((_cAliasRc0)->RECRC0))

        _cAliasZc1:= GetNextAlias()

        BeginSql Alias _cAliasZc1
        SELECT ZC1.R_E_C_N_O_ AS RECZC1
            ,ZC0.R_E_C_N_O_ AS RECZC0
            ,ZC4.R_E_C_N_O_ AS RECZC4
            ,ZCN.R_E_C_N_O_ AS RECZCN
            ,(SELECT MIN(RA_ADMISSA) FROM %TABLE:SRA% SRA
                WHERE RA_XIDCONT=ZC1_CODIGO
                    AND RA_XIDLOCT=ZC1_LOCCTR
                    AND RA_ADMISSA!=''
                    AND RA_DTFIMCT!=''
                    AND SRA.D_E_L_E_T_='') AS INICIO 
            ,(SELECT MAX(RA_DTFIMCT) FROM %TABLE:SRA% SRA
                WHERE RA_XIDCONT=ZC1_CODIGO
                    AND RA_XIDLOCT=ZC1_LOCCTR
                    AND RA_ADMISSA!=''
                    AND RA_DTFIMCT!=''
                    AND SRA.D_E_L_E_T_='') AS FIM                    
        FROM %TABLE:ZC1% ZC1	
        INNER JOIN %Table:ZC0% ZC0 ON ZC0_FILIAL=ZC1_FILIAL
            AND ZC0_FORPGT='2'
            AND ZC0_CODIGO=ZC1_CODIGO
            AND ZC0.D_E_L_E_T_=''
        INNER JOIN %TABLE:ZC4% ZC4 ON ZC4_IDCONT=ZC1_CODIGO
            AND ZC4_STATUS='1'
            AND ZC4_TIPCON != '3'
            AND ZC4.D_E_L_E_T_=''
        INNER JOIN %TABLE:ZC3%  ZC3 
            ON ZC1_CODIGO = ZC3_IDCONT 
            AND ZC3.D_E_L_E_T_ = ''            
        INNER JOIN %TABLE:ZCN% ZCN ON ZCN_CODIGO=ZC3_UNRESP 
            AND ZCN.D_E_L_E_T_=''                
        WHERE ZC1_FILIAL=%xfilial:ZC1%
            AND ZC1.D_E_L_E_T_=''	
            AND ZC1_PROVBA=''
            AND (SELECT COUNT(*) FROM %TABLE:SRA% SRA
                WHERE RA_XIDCONT=ZC1_CODIGO
                    AND RA_XIDLOCT=ZC1_LOCCTR
                    AND SRA.D_E_L_E_T_='') > 0       
        ORDER BY ZC1_CODIGO,ZC1_LOCCTR
        EndSql

        TCSETFIELD(_cAliasZc1,"INICIO","D")
        TCSETFIELD(_cAliasZc1,"FIM","D")

        //GETLastQuery()[2]
        While (_cAliasZc1)->(!Eof())

            ZC0->(DBGOTO((_cAliasZc1)->RECZC0))
            ZC1->(DBGOTO((_cAliasZc1)->RECZC1))
            ZC4->(DBGOTO((_cAliasZc1)->RECZC4))
            ZCN->(DBGOTO((_cAliasZc1)->RECZCN))

            //Refaz provisionamentos
            DelProvCP(ZC1->ZC1_CODIGO, ZC1->ZC1_LOCCTR)

            _nTotTit:= DateDiffMonth((_cAliasZc1)->INICIO,(_cAliasZc1)->FIM)
            _dDtVenc:= LastDate((_cAliasZc1)->INICIO)

            For _nCnt:= 1 to _nTotTit

                if _dDtVenc > _dDtIni

                    _cAliasSra:= GetNextAlias()
                    BeginSql Alias _cAliasSra
                    SELECT COUNT(*) AS TOTAL,SUM(RA_SALARIO) AS VALOR FROM %TABLE:SRA% SRA
                    WHERE RA_XIDCONT=%Exp:ZC1->ZC1_CODIGO%
                        AND RA_XIDLOCT=%Exp:ZC1->ZC1_LOCCTR%
                        AND %Exp:_dDtVenc% BETWEEN RA_ADMISSA AND RA_DTFIMCT
                        AND RA_ADMISSA!=''
                        AND RA_DTFIMCT!=''
                        AND SRA.D_E_L_E_T_=''    
                    EndSql

                    //GETLastQuery()[2]
                    if (_cAliasSra)->(!Eof())
                        
                        //Contribuição Fixa ou faixas                                                                                           
                        IF ZC4->ZC4_TIPCON == "1"
                            
                            nVlrCnt:= ZC4->ZC4_VLRCON

                            oJson:= JsonObject():new()
                            oJson:fromJson(ALLTRIM(ZC4->ZC4_FAIXAS))
                            For nX:=1 to len(oJson["FAIXAS"])
                                IF (_cAliasSra)->TOTAL >= val(oJson["FAIXAS"][nX]:GetJsonText("minimo")) .AND. (_cAliasSra)->TOTAL <= val(oJson["FAIXAS"][nX]:GetJsonText("maximo"))
                                    nVlrCnt:= val(oJson["FAIXAS"][nX]:GetJsonText("valorCI"))
                                ENDIF    
                            Next  

                            FreeObj(oJson)                            
                            
                            IncProvCP(ZC1->ZC1_CODIGO,;
                                ZC1->ZC1_LOCCTR,;
                                RC0->RC0_PREFIX,;
                                RC0->RC0_FORNEC,;
                                RC0->RC0_LOJA,;
                                _dDtVenc,;
                                (_cAliasSra)->TOTAL * nVlrCnt,;
                                RC0->RC0_NATURE)

                        //Contribuição Percentual
                        ELSEIF ZC4->ZC4_TIPCON == "2"

                            IncProvCP(ZC1->ZC1_CODIGO,;
                                ZC1->ZC1_LOCCTR,;
                                RC0->RC0_PREFIX,;
                                RC0->RC0_FORNEC,;
                                RC0->RC0_LOJA,;
                                _dDtVenc,;
                                (_cAliasSra)->TOTAL * (VAL(ZC4->ZC4_PERCON) * (_cAliasSra)->VALOR / 100),;
                                RC0->RC0_NATURE)                        
                      
                        ENDIF        

                    Endif

                    (_cAliasSra)->(dbCloseArea())

                endif

                _dDtVenc:= LastDate(_dDtVenc+1)

            Next
            
            lGravado := .T.

            RECLOCK("ZC1",.F.)
            ZC1->ZC1_PROVBA='S'
            MSUNLOCK()

            (_cAliasZc1)->(dbSkip())
        End

        (_cAliasZc1)->(dbCloseArea())

    Else
        If _lJob
            U_CJBK06LOG(1,"Banco de provisionamento de BA não configurado na RC0!")
        Else
            msginfo("Banco de provisionamento de BA não configurado na RC0!")
        Endif
    Endif

//Realiza provisionamento de CI
    _cAliasZc1:= GetNextAlias()
    BeginSql Alias _cAliasZc1
	SELECT ZC1.R_E_C_N_O_ AS RECZC1
          ,ZC0.R_E_C_N_O_ AS RECZC0
          ,ZC4.R_E_C_N_O_ AS RECZC4
          ,ZCN.R_E_C_N_O_ AS RECZCN
          ,(SELECT MIN(RA_ADMISSA) FROM %TABLE:SRA% SRA
            WHERE RA_XIDCONT=ZC1_CODIGO
                AND RA_XIDLOCT=ZC1_LOCCTR
                AND RA_ADMISSA!=''
                AND RA_DTFIMCT!=''
                AND SRA.D_E_L_E_T_='') AS INICIO 
          ,(SELECT MAX(RA_DTFIMCT) FROM %TABLE:SRA% SRA
            WHERE RA_XIDCONT=ZC1_CODIGO
                AND RA_XIDLOCT=ZC1_LOCCTR
                AND RA_ADMISSA!=''
                AND RA_DTFIMCT!=''
                AND SRA.D_E_L_E_T_='') AS FIM       
	FROM %TABLE:ZC1% ZC1			
    INNER JOIN %Table:ZC0% ZC0 ON ZC0_FILIAL=ZC1_FILIAL
        AND ZC0_CODIGO=ZC1_CODIGO
        AND ZC0.D_E_L_E_T_=''     
    INNER JOIN %TABLE:ZC4% ZC4 ON ZC4_IDCONT=ZC1_CODIGO
        AND ZC4_STATUS='1'
        AND ZC4_TIPCON != '3'
        AND ZC4.D_E_L_E_T_='' 
    INNER JOIN %TABLE:ZC3%  ZC3 
        ON ZC1_CODIGO = ZC3_IDCONT 
        AND ZC3.D_E_L_E_T_ = ''       
    INNER JOIN %TABLE:ZCN% ZCN ON ZCN_CODIGO=ZC3_UNRESP
        AND ZCN.D_E_L_E_T_=''              		 	
	WHERE ZC1_FILIAL=%xfilial:ZC1%
		AND ZC1.D_E_L_E_T_=''	
        AND ZC1_PROVCI=''   
        AND (
            SELECT COUNT(*) FROM %TABLE:SRA% SRA
            WHERE RA_XIDCONT=ZC1_CODIGO
                AND RA_XIDLOCT=ZC1_LOCCTR
                AND SRA.D_E_L_E_T_='') > 0              
	ORDER BY ZC1_CODIGO,ZC1_LOCCTR
    EndSql

    TCSETFIELD(_cAliasZc1,"INICIO","D")
    TCSETFIELD(_cAliasZc1,"FIM","D")

//GETLastQuery()[2]
    While (_cAliasZc1)->(!Eof())
        ZC0->(DBGOTO((_cAliasZc1)->RECZC0))
        ZC1->(DBGOTO((_cAliasZc1)->RECZC1))
        ZC4->(DBGOTO((_cAliasZc1)->RECZC4))
        ZCN->(DBGOTO((_cAliasZc1)->RECZCN))

        //Refaz provisionamentos
        DelProvCR(ZC1->ZC1_CODIGO, ZC1->ZC1_LOCCTR)

        _nTotTit:= DateDiffMonth((_cAliasZc1)->INICIO,(_cAliasZc1)->FIM)
        _dDtVenc:= LastDate((_cAliasZc1)->INICIO)

        For _nCnt:= 1 to _nTotTit

            if _dDtVenc > _dDtIni

                _cAliasSra:= GetNextAlias()
                BeginSql Alias _cAliasSra
                SELECT COUNT(*) AS TOTAL,SUM(RA_SALARIO) AS VALOR FROM %TABLE:SRA% SRA 
                WHERE RA_XIDCONT=%Exp:ZC1->ZC1_CODIGO%
                    AND RA_XIDLOCT=%Exp:ZC1->ZC1_LOCCTR%
                    AND %Exp:_dDtVenc% BETWEEN RA_ADMISSA AND RA_DTFIMCT
                    AND RA_ADMISSA!=''
                    AND RA_DTFIMCT!=''
                    AND SRA.D_E_L_E_T_=''
                EndSql

                //GETLastQuery()[2]
                if (_cAliasSra)->(!Eof())


                    //Contribuição Fixa ou faixas                                                                                           
                    IF ZC4->ZC4_TIPCON == "1"
                        
                        nVlrCnt:= ZC4->ZC4_VLRCON

                        oJson:= JsonObject():new()
                        oJson:fromJson(ALLTRIM(ZC4->ZC4_FAIXAS))
                        For nX:=1 to len(oJson["FAIXAS"])
                            IF (_cAliasSra)->TOTAL >= val(oJson["FAIXAS"][nX]:GetJsonText("minimo")) .AND. (_cAliasSra)->TOTAL <= val(oJson["FAIXAS"][nX]:GetJsonText("maximo"))
                                nVlrCnt:= val(oJson["FAIXAS"][nX]:GetJsonText("valorCI"))
                            ENDIF    
                        Next  

                        FreeObj(oJson)    

                        IncProvCR(ZC1->ZC1_CODIGO,;
                            ZC1->ZC1_LOCCTR,;
                            _dDtVenc,;
                            (_cAliasSra)->TOTAL * nVlrCnt)                                                                        

                    //Contribuição Percentual
                    ELSEIF ZC4->ZC4_TIPCON == "2"

                        IncProvCR(ZC1->ZC1_CODIGO,;
                            ZC1->ZC1_LOCCTR,;
                            _dDtVenc,;
                            (_cAliasSra)->TOTAL * (VAL(ZC4->ZC4_PERCON) * (_cAliasSra)->VALOR / 100))                                           
                    
                    ENDIF                   

                Endif

                (_cAliasSra)->(dbCloseArea())
            endif

            _dDtVenc:= LastDate(_dDtVenc+1)

        Next
        
        lGravado := .T.
        
        RECLOCK("ZC1",.F.)
        ZC1->ZC1_PROVCI='S'
        MSUNLOCK()

        (_cAliasZc1)->(dbSkip())
    End

    (_cAliasZc1)->(dbCloseArea())

Return

/*/{Protheus.doc} IncProvCP
Inclui titulos provisórios contas a pagar
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
Static Function IncProvCP(_cContra, _cLocCtr, _cPrefixo, _cCodForn, _cLojForn, _dDtVenc, _nValTit, _cNatTit)
    Local _cTabNum:= GetNextAlias()
    Local _cCompet:= STRZERO(MONTH(_dDtVenc),2)+STRZERO(YEAR(_dDtVenc),4)
    Local _dEmis  := CTOD(STRZERO(DAY(DDATABASE),2)+"/"+;
        STRZERO(MONTH(_dDtVenc),2)+"/"+;
        STRZERO(YEAR(_dDtVenc),4))
    Local _cNumTit:= ""


    BeginSql Alias _cTabNum
	SELECT MAX(E2_NUM) AS NUM 
	FROM %TABLE:SE2% SE2			 		 	
	WHERE E2_FILIAL=%xfilial:SE2%
		AND E2_TIPO = 'PR '
        AND E2_PREFIXO = %Exp:_cPrefixo%
		AND SE2.D_E_L_E_T_=''	
    EndSql

    _cNumTit := SOMA1((_cTabNum)->NUM)

    (_cTabNum)->(dbCloseArea())

    SA2->(dbSetOrder(1))
    SA2->(dbSeek(xFilial("SA2")+ _cCodForn + _cLojForn ))

    RecLock("SE2",.T.)
    SE2->E2_FILIAL    := xFilial("SE2")
    SE2->E2_PREFIXO   := _cPrefixo
    SE2->E2_NUM       := _cNumTit
    SE2->E2_PARCELA   := "   "
    SE2->E2_TIPO      := "PR"
    SE2->E2_FORNECE   := SA2->A2_COD
    SE2->E2_LOJA      := SA2->A2_LOJA
    SE2->E2_NOMFOR    := SA2->A2_NREDUZ
    SE2->E2_EMIS1     := _dEmis
    SE2->E2_EMISSAO   := _dEmis
    SE2->E2_VENCTO    := _dDtVenc
    SE2->E2_VENCREA   := _dDtVenc
    SE2->E2_VENCORI   := _dDtVenc
    SE2->E2_VALOR     := _nValTit
    SE2->E2_MOEDA     := 1
    SE2->E2_SALDO     := SE2->E2_VALOR
    SE2->E2_NATUREZ   := _cNatTit
    SE2->E2_VLCRUZ    := _nValTit
    SE2->E2_ORIGEM    := "CJOBK06"
    SE2->E2_RATEIO    := "N"
    SE2->E2_FLUXO     := "S"
    SE2->E2_FILORIG	  := cFilAnt
    SE2->E2_XIDCNT	  := _cContra
    SE2->E2_XIDLOC	  := _cLocCtr
    SE2->E2_XRAZSOC   := SA2->A2_NOME
    SE2->E2_XCOMPET   := _cCompet

    MsUnlock()

    FaAvalSE2(1,SE2->E2_ORIGEM)

Return

/*/{Protheus.doc} IncProvCP
Exclui titulos provisórios contas a pagar
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
Static Function DelProvCP(_cContra, _cLocCtr)
    Local _cTabDel:= GetNextAlias()

    dbselectarea("SE2")

    BeginSql Alias _cTabDel
	SELECT SE2.R_E_C_N_O_ AS RECSE2
	FROM %TABLE:SE2% SE2			 		 	
	WHERE E2_FILIAL=%xfilial:SE2%
		AND E2_TIPO = 'PR '
        AND E2_XIDCNT = %Exp:_cContra%
        AND E2_XIDLOC = %Exp:_cLocCtr%
		AND SE2.D_E_L_E_T_=''
    EndSql

//GETLastQuery()[2]
    While (_cTabDel)->(!Eof())

        SE2->(DBGOTO((_cTabDel)->RECSE2))

        RecLock("SE2",.F.)
        dbDelete()
        FaAvalSE2(2,"CJOBK06")
        FaAvalSE2(3,"CJOBK06")
        MsUnlock()

        (_cTabDel)->(dbSkip())
    End

    (_cTabDel)->(dbCloseArea())

Return

/*/{Protheus.doc} IncProvCRIncProvCR
Inclui titulos provisórios contas a receber
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
Static Function IncProvCR(_cContra, _cLocCtr, _dDtVenc, _nValTit)
    Local _cTabNum := ""
    Local _cNumTit := ""
    Local aCliProv := {}
    Local aLogCli  := {}
    Local _cPrefixo:= "NF "
    Local cItemDef := "998"
    Local _cCompet := STRZERO(MONTH(_dDtVenc),2)+STRZERO(YEAR(_dDtVenc),4)
    Local _dEmis   := CTOD(STRZERO(DAY(DDATABASE),2)+"/"+;
        STRZERO(MONTH(_dDtVenc),2)+"/"+;
        STRZERO(YEAR(_dDtVenc),4))

    IF U_CJBKCLI(@aCliProv, _cContra, _cLocCtr, @aLogCli)

        _cTabNum:= GetNextAlias()

        BeginSql Alias _cTabNum
        SELECT MAX(E1_NUM) AS NUM 
        FROM %TABLE:SE1% SE1			 		 	
        WHERE E1_FILIAL=%xfilial:SE1%
            AND E1_TIPO = 'PR '
            AND E1_PREFIXO = %Exp:_cPrefixo%
            AND SE1.D_E_L_E_T_=''	
        EndSql

        _cNumTit := SOMA1((_cTabNum)->NUM)

        (_cTabNum)->(dbCloseArea())

        SA1->(dbSetOrder(1))
        SA1->(dbSeek(xFilial("SA1")+ aCliProv[1] + aCliProv[2] ))

        RecLock("SE1",.T.)
        SE1->E1_FILIAL    := xFilial("SE1")
        SE1->E1_PREFIXO   := _cPrefixo
        SE1->E1_NUM       := _cNumTit
        SE1->E1_PARCELA   := "   "
        SE1->E1_TIPO      := "PR"
        SE1->E1_CLIENTE   := SA1->A1_COD
        SE1->E1_LOJA      := SA1->A1_LOJA
        SE1->E1_NOMCLI    := SA1->A1_NREDUZ
        SE1->E1_EMIS1     := _dEmis
        SE1->E1_EMISSAO   := _dEmis
        SE1->E1_VENCTO    := _dDtVenc
        SE1->E1_VENCREA   := _dDtVenc
        SE1->E1_VENCORI   := _dDtVenc
        SE1->E1_VALOR     := _nValTit
        SE1->E1_MOEDA     := 1
        SE1->E1_SALDO     := SE1->E1_VALOR
        SE1->E1_NATUREZ   := SA1->A1_NATUREZ
        SE1->E1_VLCRUZ    := _nValTit
        SE1->E1_ORIGEM    := "CJOBK06"
        SE1->E1_FLUXO     := "S"
        SE1->E1_FILORIG	  := cFilAnt
        SE1->E1_XIDCNT	  := _cContra
        SE1->E1_XIDLOC	  := _cLocCtr
        SE1->E1_XCOMPET   := _cCompet

        if cCnpjBB == SUBSTR(ZC1->ZC1_DOCLOC, 1, 8)

            //Tipo de contratação
            if ZC0->ZC0_TIPCON == "1" //Estagio

                SE1->E1_XREDUZ  := "13001"
                SE1->E1_DEBITO  := "101020400001"
                SE1->E1_XREDCRE := "52104"
                SE1->E1_CREDIT  := "501020100004"
                SE1->E1_HIST    := "ESTAGIO BANCO DO BRASIL"
            
            elseif ZC0->ZC0_TIPCON == "2" //Aprendiz

                IF ZC0->ZC0_TIPAPR == "1" //Capacitador

                    SE1->E1_XREDUZ  := "13002"
                    SE1->E1_DEBITO  := "101020400002"
                    SE1->E1_XREDCRE := "51101"
                    SE1->E1_CREDIT  := "501010100001"
                    SE1->E1_HIST    := "APRENDIZ CAPACITADOR"

                ELSEIF ZC0->ZC0_TIPAPR == "2" //2=Empregador e Capacitador

                    SE1->E1_XREDUZ  := "13005"
                    SE1->E1_DEBITO  := "101020400005"
                    SE1->E1_XREDCRE := "51104"
                    SE1->E1_CREDIT  := "501010100004"
                    SE1->E1_HIST    := "APRENDIZ EMPREGADOR"

                ENDIF

            endif

        elseif cCnpjCX == SUBSTR(ZC1->ZC1_DOCLOC, 1, 8)

            //Tipo de contratação
            if ZC0->ZC0_TIPCON == "1" //Estagio

                SE1->E1_XREDUZ  := "13001"
                SE1->E1_DEBITO  := "101020400001"
                SE1->E1_XREDCRE := "52103"
                SE1->E1_CREDIT  := "501020100003"
                SE1->E1_HIST    := "ESTAGIO CAIXA ECONOMICA"

            elseif ZC0->ZC0_TIPCON == "2" //Aprendiz

                IF ZC0->ZC0_TIPAPR == "1" //Capacitador

                    SE1->E1_XREDUZ  := "13002"
                    SE1->E1_DEBITO  := "101020400002"
                    SE1->E1_XREDCRE := "51101"
                    SE1->E1_CREDIT  := "501010100001"
                    SE1->E1_HIST    := "APRENDIZ CAPACITADOR"

                ELSEIF ZC0->ZC0_TIPAPR == "2" //2=Empregador e Capacitador

                    SE1->E1_XREDUZ  := "13005"
                    SE1->E1_DEBITO  := "101020400005"
                    SE1->E1_XREDCRE := "51104"
                    SE1->E1_CREDIT  := "501010100004"
                    SE1->E1_HIST    := "APRENDIZ EMPREGADOR"

                ENDIF

            endif
        
        //Privada 
        elseif ZC0->ZC0_TIPEMP=="1"

            //Tipo de contratação
            if ZC0->ZC0_TIPCON == "1" //Estagio

                SE1->E1_XREDUZ  := "13001"
                SE1->E1_DEBITO  := "101020400001"
                SE1->E1_XREDCRE := "52101"//"52103"
                SE1->E1_CREDIT  := "501020100001"//"501020100003"
                SE1->E1_HIST    := "ESTAGIO EMPRESAS PRIVADAS"

            elseif ZC0->ZC0_TIPCON == "2" //Aprendiz

                IF ZC0->ZC0_TIPAPR == "1" //Capacitador

                    SE1->E1_XREDUZ  := "13002"
                    SE1->E1_DEBITO  := "101020400002"
                    SE1->E1_XREDCRE := "51101"
                    SE1->E1_CREDIT  := "501010100001"
                    SE1->E1_HIST    := "APRENDIZ CAPACITADOR"

                ELSEIF ZC0->ZC0_TIPAPR == "2" //2=Empregador e Capacitador

                    SE1->E1_XREDUZ  := "13005"
                    SE1->E1_DEBITO  := "101020400005"
                    SE1->E1_XREDCRE := "51104"
                    SE1->E1_CREDIT  := "501010100004"
                    SE1->E1_HIST    := "APRENDIZ EMPREGADOR"

                ENDIF

            endif

        //Publica
        elseif ZC0->ZC0_TIPEMP == "2" 

            //Tipo de contratação
            if ZC0->ZC0_TIPCON == "1" //Estagio

                SE1->E1_XREDUZ  := "13001"
                SE1->E1_DEBITO  := "101020400001"
                SE1->E1_XREDCRE := "52103"//"52101"
                SE1->E1_CREDIT  := "501020100003"//"501020100001"
                SE1->E1_HIST    := "ESTAGIO ORGAOS PUBLICOS"

            elseif ZC0->ZC0_TIPCON == "2" //Aprendiz

                IF ZC0->ZC0_TIPAPR == "1" //Capacitador

                    SE1->E1_XREDUZ  := "13002"
                    SE1->E1_DEBITO  := "101020400002"
                    SE1->E1_XREDCRE := "51101"
                    SE1->E1_CREDIT  := "501010100001"
                    SE1->E1_HIST    := "APRENDIZ CAPACITADOR"

                ELSEIF ZC0->ZC0_TIPAPR == "2" //2=Empregador e Capacitador

                    SE1->E1_XREDUZ  := "13005"
                    SE1->E1_DEBITO  := "101020400005"
                    SE1->E1_XREDCRE := "51104"
                    SE1->E1_CREDIT  := "501010100004"
                    SE1->E1_HIST    := "APRENDIZ EMPREGADOR"

                ENDIF

            endif

        //Mista
        elseif ZC0->ZC0_TIPEMP=="3"

            //Tipo de contratação
            if ZC0->ZC0_TIPCON == "1" //Estagio

                SE1->E1_XREDUZ  := "13001"
                SE1->E1_DEBITO  := "101020400001"
                SE1->E1_XREDCRE := "52102"
                SE1->E1_CREDIT  := "501020100002"
                SE1->E1_HIST    := "ESTAGIO EMPRESAS ECONOMIA MISTA"

            elseif ZC0->ZC0_TIPCON == "2" //Aprendiz

                IF ZC0->ZC0_TIPAPR == "1" //Capacitador

                    SE1->E1_XREDUZ  := "13002"
                    SE1->E1_DEBITO  := "101020400002"
                    SE1->E1_XREDCRE := "51101"
                    SE1->E1_CREDIT  := "501010100001"
                    SE1->E1_HIST    := "APRENDIZ CAPACITADOR"

                ELSEIF ZC0->ZC0_TIPAPR == "2" //2=Empregador e Capacitador

                    SE1->E1_XREDUZ  := "13005"
                    SE1->E1_DEBITO  := "101020400005"
                    SE1->E1_XREDCRE := "51104"//"51108"
                    SE1->E1_CREDIT  := "501010100004"//"501010100008"
                    SE1->E1_HIST    := "APRENDIZ EMPREGADOR"

                ENDIF

            endif

        endif

        If !Empty(ZCN->ZCN_CRESTA)
            SE1->E1_ITEMC   := ZCN->ZCN_CRESTA
            SE1->E1_CCC     := GetAdvFVal("CTA","CTA_CUSTO" ,XFILIAL("CTA") + ZCN->ZCN_CRESTA,4)
            SE1->E1_CLVLCR  := GetAdvFVal("CTA","CTA_CLVL"  ,XFILIAL("CTA") + ZCN->ZCN_CRESTA,4)
            SE1->E1_EC05CR  := GETADVFVAL("CTA","CTA_ENTI05",XFILIAL("CTA") + ZCN->ZCN_CRESTA,4)
        Else
            SE1->E1_ITEMC   := cItemDef
            SE1->E1_CCC     := GetAdvFVal("CTA","CTA_CUSTO" ,XFILIAL("CTA") + cItemDef,4)
            SE1->E1_CLVLCR  := GetAdvFVal("CTA","CTA_CLVL"  ,XFILIAL("CTA") + cItemDef,4)
            SE1->E1_EC05CR  := GETADVFVAL("CTA","CTA_ENTI05",XFILIAL("CTA") + cItemDef,4)
        EndIf

        MsUnlock()

        FaAvalSE1(1,"CJOBK06")
    ELSE
        U_CJBK06LOG(1,aLogCli[2])
    ENDIF

Return

/*/{Protheus.doc} IncProvCR
Exclui titulos provisórios contas a receber
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
Static Function DelProvCR(_cContra, _cLocCtr)
    Local _cTabDel:= GetNextAlias()

    dbselectarea("SE1")

    BeginSql Alias _cTabDel
	SELECT SE1.R_E_C_N_O_ AS RECSE1
	FROM %TABLE:SE1% SE1			 		 	
	WHERE E1_FILIAL=%xfilial:SE1%
		AND E1_TIPO = 'PR '
        AND E1_XIDCNT = %Exp:_cContra%
        AND E1_XIDLOC = %Exp:_cLocCtr%
		AND SE1.D_E_L_E_T_=''
    EndSql

//GETLastQuery()[2]
    While (_cTabDel)->(!Eof())

        SE1->(DBGOTO((_cTabDel)->RECSE1))

        RecLock("SE1",.F.)
        dbDelete()
        FaAvalSE1(2,"CJOBK06")
        FaAvalSE1(3,"CJOBK06")
        MsUnlock()

        (_cTabDel)->(dbSkip())
    End

    (_cTabDel)->(dbCloseArea())

Return

/*/{Protheus.doc} ProcCTB
Rotina de contabilização da provisão de CI
@author carlos.henrique
@since 30/01/2018
@version undefined

@type function
/*/
static Function ProcCTB()
    LOCAL cPadrao  := "X02"    //LP Provisão de CI (TABELAS ==> CT5,CVA E CTL)
    LOCAL cLote    := "990001" //Provisão de CI
    LOCAL cArquivo := ''
    LOCAL nTotal   := 0
    LOCAL nHdlPrv  := 0
    Local dBkpDta  := DDATABASE
    Local cTDt     := ""
    Local aDtRec   := {}
    Local nX       := 0
    Local nY       := 0
    Local nPos     := 0

    IF VerPadrao(cPadrao)

        DbSelectArea( 'SE1' )

        cTDt:= GetNextAlias()

        BeginSql Alias cTDt
        SELECT E1_EMISSAO,R_E_C_N_O_ FROM %Table:SE1% SE1
        WHERE E1_FILIAL=%xFilial:SE1%
            AND E1_TIPO='PR '
            AND E1_LA=''
            AND E1_XIDCNT<> ''
            AND SE1.D_E_L_E_T_=''                 
        ORDER BY E1_EMISSAO
        EndSql

        (cTDt)->( DbGoTop())

        Do While (cTDt)->( !EOF() )

            nPos := aScan( aDtRec, {|X| X[1] == (cTDt)->E1_EMISSAO } )

            If nPos == 0

                (cTDt)->( aAdd( aDtRec, { E1_EMISSAO, { R_E_C_N_O_ } } ) )

            Else

                (cTDt)->( aAdd( aDtRec[ nPos, 2 ], R_E_C_N_O_ ) )

            End If

            (cTDt)->(dbskip())

        End Do

        (cTDt)->(dbCloseArea())

        For nX := 1 To Len( aDtRec )

            DDATABASE:= StoD( aDtRec[ nX, 1 ] )
            nHdlPrv  := HeadProva(cLote,"CJOBK06",Substr(cUsuario,7,6),@cArquivo)

            For nY := 1 To Len( aDtRec[ nX, 2 ] )

                SE1->( DbGoto(aDtRec[nX,2,nY] ) )

                RecLock("SE1",.F.)
                SE1->E1_LA='S'
                MsUnLock()

                nTotal += DetProva( nHdlPrv,;
                    cPadrao,;
                    "CJOBK06",;
                    cLote,;
          /*nLinha*/,;
          /*lExecuta*/,;
          /*cCriterio*/,;
          /*lRateio*/,;
          /*cChaveBusca*/,;
          /*aCT5*/,;
          /*lPosiciona*/,;
          /*aFlagCTB*/,;
          /*aTabRecOri*/,;
          /*aDadosProva*/ )	


            Next nY

            IF nTotal > 0
                RodaProva(nHdlPrv,nTotal)
                cA100Incl( cArquivo,;
                    nHdlPrv,;
                    3,;
                    cLote,;
                    .F.,;
                    .T.,;
          /*cOnLine*/,;
          /*dData*/,;
          /*dReproc*/,;
          /*aFlagCTB*/,;
          /*aDadosProva*/,;
          /*aDiario*/)
                End If

        Next nX

    End If

    DDATABASE:= dBkpDta

Return
/*/{Protheus.doc} Scheddef
Define parametros do processamento via schedule
@author carlos.henrique
@since 06/06/2019
@version undefined

@type function
/*/
Static Function Scheddef()
    Local aParam := {"P","CCTBS02","",{},""}
Return aParam

/*/{Protheus.doc} CJBK06LOG
Rotina de gravação do log
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
User Function CJBK06LOG(nTpLog,cMsgLog)
    default cMsgLog	:= ""

    Do Case
    Case nTpLog == 1 //Exibe log em tela ou console

        CONOUT(cMsgLog)

    Otherwise
        CONOUT(cMsgLog)
    EndCase CASE

return
