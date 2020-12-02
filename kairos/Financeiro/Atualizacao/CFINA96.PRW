#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
//--------------------------------------------------------------------------------------- 
/*/{Protheus.doc} CFINA96
Programa responsável em Baixar Titulos a Pagar através da EXECAUTO Fina080 
Chamado pelo Ponto de Entrada F430COMP que Trata O Retorno do Arquivo CNAB
@type  Function
@author Luiz Enrique de Araujo
@since 15/06/2020 - Retomado em 25/06/2020
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
USER Function CFINA96(_cBanco,_cAgencia,_cConta)
Local cTInv:= ""
Local cTab:= ""
Local aTit:= {}
Local cChaveTit:= ""
Local cChaveFK7:= ""
Local cCodIncon:= TRIM(SuperGetMv("CI_VACINC" ,.F.,"000004"))  //Código de valor acessório de inconsistência
Local lAvalCli:= .F.
Local lMoveArq:= .T.
Local cTipRet:= ""
Private lMsHelpAuto:= .T.
Private lMsErroAuto:= .F.
Private cXSeqOcor  := U_CSEQRET() //Função presenta no Programa CFINR088.PRW

cTipRet:= LEFT(cXSeqOcor,1)

//Retorno validação de estudantes
IF cTipRet == "A"

    cTInv:= GetNextAlias()

    BeginSql Alias cTInv
        SELECT *
        FROM %Table:SRA% SRA  
        WHERE SRA.D_E_L_E_T_='' 
            AND SRA.RA_FILIAL = %xFilial:SRA% 
            AND SRA.RA_XSOCOR=%Exp:cXSeqOcor% 
            AND SRA.RA_XPROCBX = 'X'
    EndSql

    //GETLastQuery()[2]
    IF (cTInv)->(EOF())

        FKC->(dbSetOrder(1))
        IF FKC->(DBSEEK(XFILIAL("FKC") + cCodIncon ))

            Pergunte("FIN080",.F.)  
                        
            //Realiza a baixa dos pagamentos realizados com sucesso            
            cTab:= GetNextAlias()            
            BeginSql Alias cTab
                SELECT DISTINCT E2_PREFIXO
                    ,E2_NUM
                    ,E2_PARCELA
                    ,E2_TIPO
                    ,E2_FORNECE
                    ,E2_LOJA
                    ,E2_VALOR
                    ,COALESCE((SELECT CAST(TOTAL AS FLOAT)/100 FROM(  
                        SELECT COUNT(*) AS TOTAL FROM %Table:SRA% SRA1
                        WHERE SRA1.D_E_L_E_T_='' 
                        AND SRA1.RA_FILIAL = %xFilial:SRA% 
                        AND SRA1.RA_XTITVLD = SE2.E2_NUM
                        AND SRA1.RA_XPROCBX = '1'
                    )AS TMP),0) VLRNOR  
                    ,COALESCE((SELECT CAST(TOTAL AS FLOAT)/100 FROM(  
                        SELECT COUNT(*) AS TOTAL FROM %Table:SRA% SRA1
                        WHERE SRA1.D_E_L_E_T_='' 
                        AND SRA1.RA_FILIAL = %xFilial:SRA% 
                        AND SRA1.RA_XTITVLD = SE2.E2_NUM
                        AND SRA1.RA_XPROCBX IN ('3','6')
                    )AS TMP),0) VLRINC  
                FROM %Table:SE2% SE2
                WHERE SE2.D_E_L_E_T_='' 
                    AND SE2.E2_FILIAL = %xFilial:SE2% 
                    AND SE2.E2_NUM IN (
                        SELECT DISTINCT RA_XTITVLD
                        FROM %Table:SRA% SRA2  
                        WHERE SRA2.D_E_L_E_T_='' 
                            AND SRA2.RA_FILIAL = %xFilial:SRA% 
                            AND SRA2.RA_XSOCOR=%Exp:cXSeqOcor%                     
                    )
                    AND SE2.E2_TIPO = "PBA"
                    AND SE2.E2_PREFIXO = "VCE"
            EndSql

            //GETLastQuery()[2]
            IF (cTab)->(!EOF())
                
                While (cTab)->(!EOF())

                    //Só realiza a baixa do titulo se teve 100% do retorno bancário
                    IF (cTab)->E2_VALOR == ((cTab)->VLRNOR + (cTab)->VLRINC)                

                        cChaveTit := xFilial("SE2") + "|" + (cTab)->E2_PREFIXO + "|" + (cTab)->E2_NUM     + "|" + (cTab)->E2_PARCELA + "|" + ;
                                                        (cTab)->E2_TIPO    + "|" + (cTab)->E2_FORNECE + "|" + (cTab)->E2_LOJA
                        
                        cChaveFK7 := FINGRVFK7("SE2", cChaveTit)

                        FKD->(dbSetOrder(1))
                        IF FKD->(dbSeek(xFilial("FKD") + cCodIncon + cChaveFK7 ))
                            RecLock("FKD",.F.)
                                DBDELETE()
                            FKD->(MsUnlock())        
                        ENDIF

                        IF (cTab)->VLRINC > 0 .and. (cTab)->VLRNOR > 0

                            RecLock("FKD",.T.)
                                FKD->FKD_FILIAL := xFilial("FKD")
                                FKD->FKD_CODIGO := cCodIncon
                                FKD->FKD_VALOR  := (cTab)->VLRINC 
                                FKD->FKD_IDDOC  := cChaveFK7
                                FKD->FKD_SALDO  := 0
                                FKD->FKD_DTBAIX := CtoD("//")
                                FKD->FKD_VLCALC := (cTab)->VLRINC * -1
                                FKD->FKD_VLINFO := (cTab)->VLRINC * -1
                            FKD->(MsUnlock())

                            aTit:= {}

                            aAdd(aTit,{"E2_FILIAL"  , xFilial("SE2")        , NIL})
                            aAdd(aTit,{"E2_PREFIXO" , (cTab)->E2_PREFIXO    , NIL})
                            aAdd(aTit,{"E2_NUM"     , (cTab)->E2_NUM        , NIL})
                            aAdd(aTit,{"E2_PARCELA" , (cTab)->E2_PARCELA    , NIL})
                            aAdd(aTit,{"E2_TIPO"    , (cTab)->E2_TIPO       , NIL})
                            aAdd(aTit,{"E2_FORNECE" , (cTab)->E2_FORNECE    , NIL})
                            aAdd(aTit,{"E2_LOJA"    , (cTab)->E2_LOJA       , NIL})
                            aAdd(aTit,{"AUTMOTBX"   , "NOR"                 , NIL})
                            aAdd(aTit,{"AUTBANCO"   , _cBanco               , NIL})
                            aAdd(aTit,{"AUTAGENCIA" , _cAgencia             , NIL})
                            aAdd(aTit,{"AUTCONTA"   , _cConta               , NIL})
                            aAdd(aTit,{"AUTDTBAIXA" , dDataBase             , NIL})
                            aAdd(aTit,{"AUTDTDEB"   , dDataBase             , NIL})
                            aAdd(aTit,{"AUTCHEQUE"  , ""                    , NIL})
                            aAdd(aTit,{"AUTHIST"    , "BAIXA SPBA"          , NIL})
                            aAdd(aTit,{"AUTDESCONT" , 0                     , NIL})
                            AADD(aTit,{"AUTMULTA"   , 0                     , Nil})
                            AADD(aTit,{"AUTJUROS"   , 0                     , Nil})
                            AADD(aTit,{"AUTOUTGAS"  , 0                     , Nil})
                            aAdd(aTit,{"AUTVLRPG"   , (cTab)->VLRNOR        , NIL}) 

                            lMsHelpAuto:= .T.
                            lMsErroAuto:= .F.

                            MSExecAuto({|x, y, a, b, c, d| FINA080(x, y, a, b, c, d)}, aTit, 3,,,.T.,.T.)
                                
                            IF lMsErroAuto
                                Mostraerro() 
                            ELSE
                                
                                RECLOCK("SE5",.F.)
                                SE5->E5_TIPODOC:= "BA"
                                MSUNLOCK()

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRA") + " SET RA_XPROCBX ='2"+;
                                            "' WHERE RA_FILIAL='"  + xFilial("SRA") +"' AND RA_XPROCBX ='1' AND RA_XTITVLD='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())
                                ENDIF    

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRA") + " SET RA_XPROCBX ='4"+;
                                            "' WHERE RA_FILIAL='"  + xFilial("SRA") +"' AND RA_XPROCBX ='3' AND RA_XTITVLD='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())
                                ENDIF 

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRA") + " SET RA_XPROCBX ='7"+;
                                            "' WHERE RA_FILIAL='"  + xFilial("SRA") +"' AND RA_XPROCBX ='6' AND RA_XTITVLD='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())
                                ENDIF                                 

                            ENDIF                
                        
                        ELSEIF (cTab)->VLRINC == 0 .and. (cTab)->VLRNOR > 0

                            aTit:= {}

                            aAdd(aTit,{"E2_FILIAL"  , xFilial("SE2")        , NIL})
                            aAdd(aTit,{"E2_PREFIXO" , (cTab)->E2_PREFIXO    , NIL})
                            aAdd(aTit,{"E2_NUM"     , (cTab)->E2_NUM        , NIL})
                            aAdd(aTit,{"E2_PARCELA" , (cTab)->E2_PARCELA    , NIL})
                            aAdd(aTit,{"E2_TIPO"    , (cTab)->E2_TIPO       , NIL})
                            aAdd(aTit,{"E2_FORNECE" , (cTab)->E2_FORNECE    , NIL})
                            aAdd(aTit,{"E2_LOJA"    , (cTab)->E2_LOJA       , NIL})
                            aAdd(aTit,{"AUTMOTBX"   , "NOR"                 , NIL})
                            aAdd(aTit,{"AUTBANCO"   , _cBanco               , NIL})
                            aAdd(aTit,{"AUTAGENCIA" , _cAgencia             , NIL})
                            aAdd(aTit,{"AUTCONTA"   , _cConta               , NIL})
                            aAdd(aTit,{"AUTDTBAIXA" , dDataBase             , NIL})
                            aAdd(aTit,{"AUTDTDEB"   , dDataBase             , NIL})
                            aAdd(aTit,{"AUTCHEQUE"  , ""                    , NIL})
                            aAdd(aTit,{"AUTHIST"    , "BAIXA SPBA"          , NIL})
                            aAdd(aTit,{"AUTDESCONT" , 0                     , NIL})
                            AADD(aTit,{"AUTMULTA"   , 0                     , Nil})
                            AADD(aTit,{"AUTJUROS"   , 0                     , Nil})
                            AADD(aTit,{"AUTOUTGAS"  , 0                     , Nil})
                            aAdd(aTit,{"AUTVLRPG"   , (cTab)->VLRNOR        , NIL})             

                            lMsHelpAuto:= .T.
                            lMsErroAuto:= .F.

                            MSExecAuto({|x, y, a, b, c, d| FINA080(x, y, a, b, c, d)}, aTit, 3,,,.T.,.T.)
                                
                            IF lMsErroAuto
                                Mostraerro() 
                            ELSE
                                
                                RECLOCK("SE5",.F.)
                                SE5->E5_TIPODOC:= "BA"
                                MSUNLOCK()

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRA") + " SET RA_XPROCBX ='2"+;
                                            "' WHERE RA_FILIAL='"  + xFilial("SRA") +"' AND RA_XPROCBX ='1' AND RA_XTITVLD='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())RA_XPROCBX
                                ENDIF    

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRA") + " SET RA_XPROCBX ='4"+;
                                            "' WHERE RA_FILIAL='"  + xFilial("SRA") +"' AND RA_XPROCBX ='3' AND RA_XTITVLD='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())
                                ENDIF  

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRA") + " SET RA_XPROCBX ='7"+;
                                            "' WHERE RA_FILIAL='"  + xFilial("SRA") +"' AND RA_XPROCBX ='6' AND RA_XTITVLD='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())
                                ENDIF                                 

                            ENDIF            

                        ELSE
                        
                            aTit:= {}

                            aAdd(aTit,{"E2_FILIAL"  , xFilial("SE2")        , NIL})
                            aAdd(aTit,{"E2_PREFIXO" , (cTab)->E2_PREFIXO    , NIL})
                            aAdd(aTit,{"E2_NUM"     , (cTab)->E2_NUM        , NIL})
                            aAdd(aTit,{"E2_PARCELA" , (cTab)->E2_PARCELA    , NIL})
                            aAdd(aTit,{"E2_TIPO"    , (cTab)->E2_TIPO       , NIL})
                            aAdd(aTit,{"E2_FORNECE" , (cTab)->E2_FORNECE    , NIL})
                            aAdd(aTit,{"E2_LOJA"    , (cTab)->E2_LOJA       , NIL})
                            aAdd(aTit,{"AUTMOTBX"   , "INC"                 , NIL})
                            aAdd(aTit,{"AUTBANCO"   , ""                    , NIL})
                            aAdd(aTit,{"AUTAGENCIA" , ""                    , NIL})
                            aAdd(aTit,{"AUTCONTA"   , ""                    , NIL})
                            aAdd(aTit,{"AUTDTBAIXA" , dDataBase             , NIL})
                            aAdd(aTit,{"AUTDTDEB"   , dDataBase             , NIL})
                            aAdd(aTit,{"AUTCHEQUE"  , ""                    , NIL})
                            aAdd(aTit,{"AUTHIST"    , "BAIXA SPBA"          , NIL})
                            aAdd(aTit,{"AUTDESCONT" , 0                     , NIL})
                            AADD(aTit,{"AUTMULTA"   , 0                     , Nil})
                            AADD(aTit,{"AUTJUROS"   , 0                     , Nil})
                            AADD(aTit,{"AUTOUTGAS"  , 0                     , Nil})
                            aAdd(aTit,{"AUTVLRPG"   , (cTab)->VLRINC        , NIL})            

                            lMsHelpAuto:= .T.
                            lMsErroAuto:= .F.

                            MSExecAuto({|x, y, a, b, c, d| FINA080(x, y, a, b, c, d)}, aTit, 3,,,.T.,.T.)
                                
                            IF lMsErroAuto
                                Mostraerro() 
                            ELSE  
                                
                                RECLOCK("SE5",.F.)
                                SE5->E5_TIPODOC:= "BA"
                                MSUNLOCK()

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRA") + " SET RA_XPROCBX ='4"+;
                                            "' WHERE RA_FILIAL='"  + xFilial("SRA") +"' AND RA_XPROCBX ='3' AND RA_XTITVLD='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())
                                ENDIF  

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRA") + " SET RA_XPROCBX ='7"+;
                                            "' WHERE RA_FILIAL='"  + xFilial("SRA") +"' AND RA_XPROCBX ='6' AND RA_XTITVLD='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())
                                ENDIF                                 

                            ENDIF  

                        ENDIF
                    ENDIF

                (cTab)->(dbSkip())
                END
            ENDIF

            (cTab)->(dbcloseArea())    

            // recarrega os mv_parx da rotina fina430, pois foi alterado no fina080
            pergunte("AFI430",.F.)            
        
            //Gera fila kairós 
            EnvioKairos(cTipRet)

        ELSE
            MSGALERT("Código de inconsistência " + cCodIncon+ " não cadastrado em valores acessórios!!")    
        ENDIF            
    ELSE
        lMoveArq:= .F.
        MSGALERT("No processamento do arquivo de retorno foi encontrado ocorrências bancárias não cadastrada, realize o cadastro e depois o retorno!" + CRLF +"Processo abortado!!")
    ENDIF

    (cTInv)->(dbcloseArea())

//Retorno validação de beneficiários
ELSEIF cTipRet == "B"


    cTInv:= GetNextAlias()

    BeginSql Alias cTInv
        SELECT *
        FROM %Table:SRQ% SRQ  
        WHERE SRQ.D_E_L_E_T_='' 
            AND SRQ.RQ_FILIAL = %xFilial:SRQ% 
            AND SRQ.RQ_XSOCOR=%Exp:cXSeqOcor% 
            AND SRQ.RQ_XPROCBX = 'X'
    EndSql

    //GETLastQuery()[2]
    IF (cTInv)->(EOF())
        
        //Gera fila kairós 
        EnvioKairos(cTipRet)

    ELSE
        lMoveArq:= .F.
        MSGALERT("No processamento do arquivo de retorno foi encontrado ocorrências bancárias não cadastrada, realize o cadastro e depois o retorno!" + CRLF +"Processo abortado!!")
    ENDIF

    (cTInv)->(dbcloseArea())

//Retorno pagamento de bolsa auxílio
ELSEIF cTipRet == "C"

    cTInv:= GetNextAlias()

    BeginSql Alias cTInv
        SELECT *
        FROM %Table:SRD% SRD  
        WHERE SRD.D_E_L_E_T_='' 
            AND SRD.RD_FILIAL = %xFilial:SRD% 
            AND SRD.RD_XSOCOR=%Exp:cXSeqOcor% 
            AND SRD.RD_XPROCBX = 'X'
    EndSql

    //GETLastQuery()[2]
    IF (cTInv)->(EOF())

        FKC->(dbSetOrder(1))
        IF FKC->(DBSEEK(XFILIAL("FKC") + cCodIncon ))

            Pergunte("FIN080",.F.) 
                        
            //Realiza a baixa dos pagamentos realizados com sucesso            
            cTab:= GetNextAlias()            
            BeginSql Alias cTab
                SELECT DISTINCT E2_PREFIXO
                    ,E2_NUM
                    ,E2_PARCELA
                    ,E2_TIPO
                    ,E2_FORNECE
                    ,E2_LOJA
                    ,E2_VALOR
                    ,COALESCE((SELECT SUM(RD_VALOR) FROM %Table:SRD% SRD1
                    WHERE SRD1.D_E_L_E_T_='' 
                        AND SRD1.RD_FILIAL = %xFilial:SRD% 
                        AND SRD1.RD_PD = 'J99' 
                        AND SRD1.RD_XNUMTIT = SRD.RD_XNUMTIT
                        AND SRD1.RD_XPROCBX = '1'
                    ),0) VLRNOR  
                    ,COALESCE((SELECT SUM(TOTINC) FROM(  
                        SELECT SUM(RD_VALOR) AS TOTINC FROM %Table:SRD% SRD1
                        WHERE SRD1.D_E_L_E_T_='' 
                            AND SRD1.RD_FILIAL = %xFilial:SRD% 
                            AND SRD1.RD_PD = 'J99' 
                            AND SRD1.RD_XNUMTIT = SRD.RD_XNUMTIT
                            AND SRD1.RD_XPROCBX = '3'  
                        UNION ALL
                        SELECT SUM(ZCV_VALOR) AS TOTINC FROM %Table:ZCV% ZCV
                        WHERE ZCV.D_E_L_E_T_ = ' '
                        AND ZCV.ZCV_FILIAL = %xFilial:ZCV% 
                        AND ZCV.ZCV_NUMTIT = SRD.RD_XNUMTIT
                    )AS TMP),0) VLRINC                                        
                FROM %Table:SRD% SRD  
                INNER JOIN %Table:RC1% RC1 ON  RC1_NUMTIT=RD_XNUMTIT  
                    AND RC1_PREFIX= 'PBA'  
                    AND RC1_TIPO= 'PBA'  
                    AND RC1.D_E_L_E_T_='' 
                INNER JOIN %Table:SE2% SE2 ON  E2_NUM = RC1_NUMTIT  
                    AND E2_PREFIXO = RC1_PREFIX 
                    AND E2_TIPO = RC1_TIPO  
                    AND E2_FORNECE = RC1_FORNEC  
                    AND SE2.D_E_L_E_T_='' 
                INNER JOIN %Table:SRA% SRA ON  SRA.RA_MAT = SRD.RD_MAT AND SRA.D_E_L_E_T_='' 
                WHERE SRD.D_E_L_E_T_='' 
                    AND SRD.RD_FILIAL = %xFilial:SRD% 
                    AND SRD.RD_PD = 'J99'  
                    AND SRD.RD_XSOCOR=%Exp:cXSeqOcor% 
            EndSql
            
            //GETLastQuery()[2]
            IF (cTab)->(!EOF())
                
                While (cTab)->(!EOF())
                    
                    //Só realiza a baixa do titulo se teve 100% do retorno bancário
                    IF (cTab)->E2_VALOR == ((cTab)->VLRNOR + (cTab)->VLRINC)

                        cChaveTit := xFilial("SE2") + "|" + (cTab)->E2_PREFIXO + "|" + (cTab)->E2_NUM     + "|" + (cTab)->E2_PARCELA + "|" + ;
                                                        (cTab)->E2_TIPO    + "|" + (cTab)->E2_FORNECE + "|" + (cTab)->E2_LOJA
                        
                        cChaveFK7 := FINGRVFK7("SE2", cChaveTit)

                        FKD->(dbSetOrder(1))
                        IF FKD->(dbSeek(xFilial("FKD") + cCodIncon + cChaveFK7 ))
                            RecLock("FKD",.F.)
                                DBDELETE()
                            FKD->(MsUnlock())        
                        ENDIF

                        IF (cTab)->VLRINC > 0 .and. (cTab)->VLRNOR > 0

                            RecLock("FKD",.T.)
                                FKD->FKD_FILIAL := xFilial("FKD")
                                FKD->FKD_CODIGO := cCodIncon
                                FKD->FKD_VALOR  := (cTab)->VLRINC 
                                FKD->FKD_IDDOC  := cChaveFK7
                                FKD->FKD_SALDO  := 0
                                FKD->FKD_DTBAIX := CtoD("//")
                                FKD->FKD_VLCALC := (cTab)->VLRINC * -1
                                FKD->FKD_VLINFO := (cTab)->VLRINC * -1
                            FKD->(MsUnlock())

                            aTit:= {}

                            aAdd(aTit,{"E2_FILIAL"  , xFilial("SE2")        , NIL})
                            aAdd(aTit,{"E2_PREFIXO" , (cTab)->E2_PREFIXO    , NIL})
                            aAdd(aTit,{"E2_NUM"     , (cTab)->E2_NUM        , NIL})
                            aAdd(aTit,{"E2_PARCELA" , (cTab)->E2_PARCELA    , NIL})
                            aAdd(aTit,{"E2_TIPO"    , (cTab)->E2_TIPO       , NIL})
                            aAdd(aTit,{"E2_FORNECE" , (cTab)->E2_FORNECE    , NIL})
                            aAdd(aTit,{"E2_LOJA"    , (cTab)->E2_LOJA       , NIL})
                            aAdd(aTit,{"AUTMOTBX"   , "NOR"                 , NIL})
                            aAdd(aTit,{"AUTBANCO"   , _cBanco               , NIL})
                            aAdd(aTit,{"AUTAGENCIA" , _cAgencia             , NIL})
                            aAdd(aTit,{"AUTCONTA"   , _cConta               , NIL})
                            aAdd(aTit,{"AUTDTBAIXA" , dDataBase             , NIL})
                            aAdd(aTit,{"AUTDTDEB"   , dDataBase             , NIL})
                            aAdd(aTit,{"AUTCHEQUE"  , ""                    , NIL})
                            aAdd(aTit,{"AUTHIST"    , "BAIXA SPBA"          , NIL})
                            aAdd(aTit,{"AUTDESCONT" , 0                     , NIL})
                            AADD(aTit,{"AUTMULTA"   , 0                     , Nil})
                            AADD(aTit,{"AUTJUROS"   , 0                     , Nil})
                            AADD(aTit,{"AUTOUTGAS"  , 0                     , Nil})
                            aAdd(aTit,{"AUTVLRPG"   , (cTab)->VLRNOR        , NIL}) 

                            lMsHelpAuto:= .T.
                            lMsErroAuto:= .F.

                            MSExecAuto({|x, y, a, b, c, d| FINA080(x, y, a, b, c, d)}, aTit, 3,,,.T.,.T.)
                                
                            IF lMsErroAuto
                                Mostraerro() 
                            ELSE
                                
                                RECLOCK("SE5",.F.)
                                SE5->E5_TIPODOC:= "BA"
                                MSUNLOCK()

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRD") + " SET RD_XPROCBX ='2"+;
                                            "' WHERE RD_FILIAL='"  + xFilial("SRD") +"' AND RD_XPROCBX ='1' AND RD_PD = 'J99' AND RD_XNUMTIT='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())
                                ENDIF    

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRD") + " SET RD_XPROCBX ='4"+;
                                            "' WHERE RD_FILIAL='"  + xFilial("SRD") +"' AND RD_XPROCBX ='3' AND RD_PD = 'J99' AND RD_XNUMTIT='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())
                                ENDIF 

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRD") + " SET RD_XPROCBX ='7"+;
                                            "' WHERE RD_FILIAL='"  + xFilial("SRD") +"' AND RD_XPROCBX ='6' AND RD_PD = 'J99' AND RD_XNUMTIT='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())
                                ENDIF                                 


                            ENDIF                
                        
                        ELSEIF (cTab)->VLRINC == 0 .and. (cTab)->VLRNOR > 0

                            aTit:= {}

                            aAdd(aTit,{"E2_FILIAL"  , xFilial("SE2")        , NIL})
                            aAdd(aTit,{"E2_PREFIXO" , (cTab)->E2_PREFIXO    , NIL})
                            aAdd(aTit,{"E2_NUM"     , (cTab)->E2_NUM        , NIL})
                            aAdd(aTit,{"E2_PARCELA" , (cTab)->E2_PARCELA    , NIL})
                            aAdd(aTit,{"E2_TIPO"    , (cTab)->E2_TIPO       , NIL})
                            aAdd(aTit,{"E2_FORNECE" , (cTab)->E2_FORNECE    , NIL})
                            aAdd(aTit,{"E2_LOJA"    , (cTab)->E2_LOJA       , NIL})
                            aAdd(aTit,{"AUTMOTBX"   , "NOR"                 , NIL})
                            aAdd(aTit,{"AUTBANCO"   , _cBanco               , NIL})
                            aAdd(aTit,{"AUTAGENCIA" , _cAgencia             , NIL})
                            aAdd(aTit,{"AUTCONTA"   , _cConta               , NIL})
                            aAdd(aTit,{"AUTDTBAIXA" , dDataBase             , NIL})
                            aAdd(aTit,{"AUTDTDEB"   , dDataBase             , NIL})
                            aAdd(aTit,{"AUTCHEQUE"  , ""                    , NIL})
                            aAdd(aTit,{"AUTHIST"    , "BAIXA SPBA"          , NIL})
                            aAdd(aTit,{"AUTDESCONT" , 0                     , NIL})
                            AADD(aTit,{"AUTMULTA"   , 0                     , Nil})
                            AADD(aTit,{"AUTJUROS"   , 0                     , Nil})
                            AADD(aTit,{"AUTOUTGAS"  , 0                     , Nil})
                            aAdd(aTit,{"AUTVLRPG"   , (cTab)->VLRNOR        , NIL})             

                            lMsHelpAuto:= .T.
                            lMsErroAuto:= .F.

                            MSExecAuto({|x, y, a, b, c, d| FINA080(x, y, a, b, c, d)}, aTit, 3,,,.T.,.T.)
                                
                            IF lMsErroAuto
                                Mostraerro() 
                            ELSE
                                
                                RECLOCK("SE5",.F.)
                                SE5->E5_TIPODOC:= "BA"
                                MSUNLOCK()

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRD") + " SET RD_XPROCBX ='2"+;
                                            "' WHERE RD_FILIAL='"  + xFilial("SRD") +"' AND RD_XPROCBX ='1' AND RD_PD = 'J99' AND RD_XNUMTIT='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())
                                ENDIF    

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRD") + " SET RD_XPROCBX ='4"+;
                                            "' WHERE RD_FILIAL='"  + xFilial("SRD") +"' AND RD_XPROCBX ='3' AND RD_PD = 'J99' AND RD_XNUMTIT='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())
                                ENDIF  

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRD") + " SET RD_XPROCBX ='7"+;
                                            "' WHERE RD_FILIAL='"  + xFilial("SRD") +"' AND RD_XPROCBX ='6' AND RD_PD = 'J99' AND RD_XNUMTIT='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())
                                ENDIF    

                            ENDIF            

                        ELSE
                        
                            aTit:= {}

                            aAdd(aTit,{"E2_FILIAL"  , xFilial("SE2")        , NIL})
                            aAdd(aTit,{"E2_PREFIXO" , (cTab)->E2_PREFIXO    , NIL})
                            aAdd(aTit,{"E2_NUM"     , (cTab)->E2_NUM        , NIL})
                            aAdd(aTit,{"E2_PARCELA" , (cTab)->E2_PARCELA    , NIL})
                            aAdd(aTit,{"E2_TIPO"    , (cTab)->E2_TIPO       , NIL})
                            aAdd(aTit,{"E2_FORNECE" , (cTab)->E2_FORNECE    , NIL})
                            aAdd(aTit,{"E2_LOJA"    , (cTab)->E2_LOJA       , NIL})
                            aAdd(aTit,{"AUTMOTBX"   , "INC"                 , NIL})
                            aAdd(aTit,{"AUTBANCO"   , ""                    , NIL})
                            aAdd(aTit,{"AUTAGENCIA" , ""                    , NIL})
                            aAdd(aTit,{"AUTCONTA"   , ""                    , NIL})
                            aAdd(aTit,{"AUTDTBAIXA" , dDataBase             , NIL})
                            aAdd(aTit,{"AUTDTDEB"   , dDataBase             , NIL})
                            aAdd(aTit,{"AUTCHEQUE"  , ""                    , NIL})
                            aAdd(aTit,{"AUTHIST"    , "BAIXA SPBA"          , NIL})
                            aAdd(aTit,{"AUTDESCONT" , 0                     , NIL})
                            AADD(aTit,{"AUTMULTA"   , 0                     , Nil})
                            AADD(aTit,{"AUTJUROS"   , 0                     , Nil})
                            AADD(aTit,{"AUTOUTGAS"  , 0                     , Nil})
                            aAdd(aTit,{"AUTVLRPG"   , (cTab)->VLRINC        , NIL})            

                            lMsHelpAuto:= .T.
                            lMsErroAuto:= .F.

                            MSExecAuto({|x, y, a, b, c, d| FINA080(x, y, a, b, c, d)}, aTit, 3,,,.T.,.T.)
                                
                            IF lMsErroAuto
                                Mostraerro() 
                            ELSE  
                                
                                RECLOCK("SE5",.F.)
                                SE5->E5_TIPODOC:= "BA"
                                MSUNLOCK()

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRD") + " SET RD_XPROCBX ='4"+;
                                            "' WHERE RD_FILIAL='"  + xFilial("SRD") +"' AND RD_XPROCBX ='3' AND RD_PD = 'J99' AND RD_XNUMTIT='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())
                                ENDIF  

                                IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRD") + " SET RD_XPROCBX ='7"+;
                                            "' WHERE RD_FILIAL='"  + xFilial("SRD") +"' AND RD_XPROCBX ='6' AND RD_PD = 'J99' AND RD_XNUMTIT='"+ (cTab)->E2_NUM +"' AND D_E_L_E_T_=''") < 0
                                    MSGALERT(TCSQLERROR())
                                ENDIF 

                            ENDIF  

                        ENDIF
                    ENDIF

                (cTab)->(dbSkip())
                END
            ELSE
                lAvalCli:= .T.
            ENDIF

            (cTab)->(dbcloseArea())
        ELSE
            MSGALERT("Código de inconsistência " + cCodIncon+ " não cadastrado em valores acessórios!!")    
        ENDIF

        //Avalia se é retorno de cnab de clientes
        IF lAvalCli
        //Realiza a baixa dos pagamentos realizados com sucesso            
            cTab:= GetNextAlias()            
            BeginSql Alias cTab
                SELECT SRD.R_E_C_N_O_ AS RECSRD 
                FROM %Table:SRD% SRD  
                INNER JOIN %Table:SRA% SRA ON  SRA.RA_MAT = SRD.RD_MAT AND SRA.D_E_L_E_T_='' 
                WHERE SRD.D_E_L_E_T_='' 
                    AND SRD.RD_FILIAL = %xFilial:SRD% 
                    AND SRD.RD_PD = 'J99'  
                    AND SRD.RD_XSOCOR=%Exp:cXSeqOcor% 
                    AND SRD.RD_XIDCNT IN (
                        SELECT ZCM_CODIGO
                        FROM %Table:ZCM% ZCM 
                        WHERE ZCM.D_E_L_E_T_='' 
                    )
            EndSql
            
            //GETLastQuery()[2]
            While (cTab)->(!EOF())
                
                SRD->(DbGoto((cTab)->RECSRD))
                IF SRD->(!EOF())
                    RECLOCK("SRD",.F.)
                        IF SRD->RD_XPROCBX == "1"
                            SRD->RD_XPROCBX:= "2"
                        ELSEIF SRD->RD_XPROCBX == "3"
                            SRD->RD_XPROCBX:= "4"
                        ENDIF
                    SRD->(MSUNLOCK())
                ENDIF

            (cTab)->(dbSkip())
            END
            (cTab)->(dbcloseArea())
        ENDIF

        // recarrega os mv_parx da rotina fina430, pois foi alterado no fina080
        pergunte("AFI430",.F.)

        //Gera fila kairós 
        EnvioKairos(cTipRet)

        //Realizar descalculo da bolsa com incosistência
        DescalcBolsa()        

    ELSE
        lMoveArq:= .F.
        MSGALERT("No processamento do arquivo de retorno foi encontrado ocorrências bancárias não cadastrada, realize o cadastro e depois o retorno!" + CRLF +"Processo abortado!!")
    ENDIF

    (cTInv)->(dbcloseArea())

ENDIF

Return lMoveArq
/*/{Protheus.doc} EnvioKairos 
Envio das Ocorrencias na Baixa de Títulos para Kairos
@type  Static Function
@author Luiz Enrique
@since 24/07/2020
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
Static Function EnvioKairos(cTipRet)
Local cTab  := ""   
Local cJson := ""
Local cXbanco:= ""
Local aOcorr:= {}
Local cOcorr:= ""
Local nCont:= 0
Local cDtaPag:= ""

//Retorno validação de estudantes
IF cTipRet == "A"

    //------------------------------------------------------------------------
    //Gerar fila de retorno com a validação dos dados bancários do ESTUDANTE
    //------------------------------------------------------------------------
    DbSelectarea("SRA")

    cTab:= GetNextAlias() 
    BeginSql Alias cTab
        SELECT R_E_C_N_O_ AS RECSRA        
        FROM %Table:SRA% SRA  
        WHERE SRA.D_E_L_E_T_='' 
        AND RA_FILIAL = %xFilial:SRA% 
        AND RA_XPROCBX IN ('2','3','4')
        AND RA_XSOCOR=%Exp:cXSeqOcor%  
    EndSql

    //GETLastQuery()[2]
    While (cTab)->(!EOF()) 
        
        SRA->(DbGoto((cTab)->RECSRA))
        IF SRA->(!EOF())

            aOcorr:= StrTokArr(SRA->RA_XOCOREN, "|" ) 
            cOcorr:= ""
            cRet  := ""    

            //Trata os codigos de Ocorrencia - (O Banco pode mandar ate 5 codigos de ocorrencia com 2 bytes cada concatenados)
            If len(aOcorr) > 0
                for nCont=1 to len(aOcorr)
                    cOcorr := AVKEY(aOcorr[nCont],"EB_REFBAN")   
                    SEB->(dbSetOrder(1))             
                    If SEB->(DBSEEK(XFILIAL("SEB")+cXbanco+cOcorr + "P" ))
                        cRet += ALLTRIM(aOcorr[nCont])+"-"+ALLTRIM(SEB->EB_DESCRI)+"/"
                    else
                        if !Empty(aOcorr[nCont])
                            cRet += ALLTRIM(aOcorr[nCont])+"-"+"Código de ocorrência não cadastrado/"
                        endif
                    endif
                next
            endif    

            cJson:= '{'
            cJson+= ' "tipoEnvio": "RETORNO_VALIDACAO_TCETCA",'
            cJson+= ' "operacaoEnvio": "PUT",'
            cJson+= ' "idestudante": ' + EncodeUTF8(AllTrim(SRA->RA_XID) , "cp1252") +','
            cJson+= ' "idcontrato": ' + EncodeUTF8(AllTrim(SRA->RA_XIDCONT) , "cp1252") +','         
            cJson+= ' "status": "'+ IIF(SRA->RA_XSTATOC == "1"  , "INVALIDO" ,"VALIDO")  +'",'
            cJson+= ' "motivo": "' + EncodeUTF8(AllTrim(cRet) , "cp1252") + '"'
            cJson+= '}'

            ZCQ->(RECLOCK("ZCQ",.T.))
            cIdLog:= "VT" + CVALTOCHAR(ZCQ->(RECNO()))
            ZCQ->ZCQ_FILIAL:= XFILIAL("ZCQ")
            ZCQ->ZCQ_TIPENV:= "RETORNO_VALIDACAO_TCETCA"
            ZCQ->ZCQ_OPEENV:= "1" //POST
            ZCQ->ZCQ_IDENTI:= SRA->RA_XID
            ZCQ->ZCQ_URL   := ""
            ZCQ->ZCQ_IDLOG := cIdLog
            ZCQ->ZCQ_DTINTE:= DATE()
            ZCQ->ZCQ_HRINTE:= TIME()
            ZCQ->ZCQ_STATUS:= "0"
            ZCQ->ZCQ_FILA  := ALLTRIM(GetMV("CI_FRETVLT",.T.,"dev1-retorno-validacao-tcetca-kairos"))
            ZCQ->ZCQ_CODE  := ""
            ZCQ->ZCQ_JSON  := cJson
            ZCQ->(MSUNLOCK())  

            //Ajusta status para não enviar novamente
            IF SRA->RA_XPROCBX == "3"
                RecLock("SRA",.F.)
                    SRA->RA_XPROCBX := "6"
                SRA->(MsUnlock())                
            ENDIF              

        ENDIF

        (cTab)->(dbSkip())

    End

    (cTab)->(dbcloseArea())

//Retorno validação de beneficiários
ELSEIF cTipRet == "B"

    //--------------------------------------------------------------------------
    //Gerar fila de retorno com a validação dos dados bancários do BENEFICIARIO
    //--------------------------------------------------------------------------
    DbSelectarea("SRQ")

    DbSelectarea("SRA")
    SRA->(dbSetOrder(1))

    cTab:= GetNextAlias() 
    BeginSql Alias cTab
        SELECT R_E_C_N_O_ AS RECSRQ        
        FROM %Table:SRQ% SRQ  
        WHERE SRQ.D_E_L_E_T_='' 
        AND RQ_FILIAL = %xFilial:SRQ% 
        AND RQ_XPROCBX IN ('2','3','4')
        AND RQ_XSOCOR=%Exp:cXSeqOcor%  
    EndSql

    //GETLastQuery()[2]
    SRA->(dbSetOrder(1))

    While (cTab)->(!EOF())

        SRQ->(DbGoto((cTab)->RECSRQ))
        IF SRQ->(!EOF())

            SRA->(DbSeek(xFilial("SRA") + SRQ->RQ_MAT ))

            aOcorr:= StrTokArr(SRQ->RQ_XOCOREN, "|" ) 
            cOcorr:= ""
            cRet  := ""    

            //Trata os codigos de Ocorrencia - (O Banco pode mandar ate 5 codigos de ocorrencia com 2 bytes cada concatenados)
            If len(aOcorr) > 0
                for nCont=1 to len(aOcorr)
                    cOcorr := AVKEY(aOcorr[nCont],"EB_REFBAN")   
                    SEB->(dbSetOrder(1))             
                    If SEB->(DBSEEK(XFILIAL("SEB")+cXbanco+cOcorr + "P" ))
                        cRet += ALLTRIM(aOcorr[nCont])+"-"+ALLTRIM(SEB->EB_DESCRI)+"/"
                    else
                        if !Empty(aOcorr[nCont])
                            cRet += ALLTRIM(aOcorr[nCont])+"-"+"Código de ocorrência não cadastrado/"
                        endif
                    endif
                next
            endif    

            cJson:= '{'
            cJson+= ' "tipoEnvio": "RETORNO_VALIDACAO_BENEFICIARIO",'
            cJson+= ' "operacaoEnvio": "PUT",'
            cJson+= ' "idestudante": ' + EncodeUTF8(AllTrim(SRA->RA_XID) , "cp1252") +','
            cJson+= ' "idcontrato": ' + EncodeUTF8(AllTrim(SRA->RA_XIDCONT) , "cp1252") +','
            cJson+= ' "idbeneficiario": ' + EncodeUTF8(AllTrim(SRQ->RQ_XID) , "cp1252") +','         
            cJson+= ' "status": "'+ IIF(SRQ->RQ_XSTATOC == "1" , "INVALIDO" ,"VALIDO")  +'",'
            cJson+= ' "motivo": "' + EncodeUTF8(AllTrim(cRet) , "cp1252") + '"'
            cJson+= '}'

            ZCQ->(RECLOCK("ZCQ",.T.))
            cIdLog:= "VB" + CVALTOCHAR(ZCQ->(RECNO()))
            ZCQ->ZCQ_FILIAL:= XFILIAL("ZCQ")
            ZCQ->ZCQ_TIPENV:= "RETORNO_VALIDACAO_BENEFICIARIO"
            ZCQ->ZCQ_OPEENV:= "1" //POST
            ZCQ->ZCQ_IDENTI:= SRQ->RQ_XID
            ZCQ->ZCQ_URL   := ""
            ZCQ->ZCQ_IDLOG := cIdLog
            ZCQ->ZCQ_DTINTE:= DATE()
            ZCQ->ZCQ_HRINTE:= TIME()
            ZCQ->ZCQ_STATUS:= "0"
            ZCQ->ZCQ_FILA  := ALLTRIM(GetMV("CI_FRETVLB",.T.,"dev1-retorno-validacao-beneficiario-kairos"))
            ZCQ->ZCQ_CODE  := ""
            ZCQ->ZCQ_JSON  := cJson
            ZCQ->(MSUNLOCK())  

            //Ajusta status para não enviar novamente
            IF SRQ->RQ_XPROCBX == "3"
                RecLock("SRQ",.F.)
                    SRQ->RQ_XPROCBX := "6"
                SRQ->(MsUnlock())                
            ENDIF             

        ENDIF

        (cTab)->(dbSkip())

    End

    (cTab)->(dbcloseArea())

//Retorno pagamento de bolsa auxílio
ELSEIF cTipRet == "C"

    DbSelectarea("ZC0")
    DbSelectarea("ZC7")
    DbSelectarea("ZC8")
    DbSelectarea("SRD")   
    
    cTab  := GetNextAlias() 

    //Gera fila de pagamento de bolsa kairos                    
    BeginSql Alias cTab
        SELECT LEFT(RA_BCDEPSA,3) AS BANCO
            ,ZC0.R_E_C_N_O_ AS RECZC0
            ,ZC7.R_E_C_N_O_ AS RECZC7
            ,SRD.R_E_C_N_O_ AS RECSRD
            ,(SELECT TOP 1 ZC8.R_E_C_N_O_ FROM %table:ZC8% ZC8 
                WHERE ZC8_FILIAL = %xFilial:ZC8% 
                    AND ZC8_IDFOL = ZC7_IDFOL 
                    AND ZC8_NUMTCE = RA_XID 
                    AND ZC8.D_E_L_E_T_ = ' ') AS RECZC8
            ,(SELECT ISNULL(SUM(RD_VALOR),0) FROM %table:SRD% SRDA
                WHERE SRDA.RD_XIDFOL=SRD.RD_XIDFOL
                    AND SRDA.RD_MAT=SRD.RD_MAT
                    AND SRDA.RD_PD='509'
                    AND SRDA.D_E_L_E_T_='' ) AS VALORIRRF          
        FROM %Table:SRD% SRD  
        INNER JOIN %TABLE:ZC0% ZC0 ON ZC0_FILIAL=%xFilial:ZC0%
            AND ZC0_CODIGO=RD_XIDCNT
            AND ZC0.D_E_L_E_T_=' ' 
        INNER JOIN %TABLE:ZC7% ZC7 ON ZC7_FILIAL=%xFilial:ZC7%
            AND ZC7_IDFOL=SRD.RD_XIDFOL
            AND ZC7.D_E_L_E_T_=' '
        INNER JOIN %TABLE:SRA% SRA ON RA_FILIAL=RD_FILIAL
            AND RA_MAT=RD_MAT
            AND SRA.D_E_L_E_T_=' '                           
        WHERE SRD.D_E_L_E_T_='' 
            AND SRD.RD_FILIAL = %xFilial:SRD% 
            AND SRD.RD_XPROCBX IN ('2','3','4') 
            AND SRD.RD_PD = 'J99' 
            AND SRD.RD_XSOCOR=%Exp:cXSeqOcor%        
    EndSql

    //GETLastQuery()[2]
    While (cTab)->(!EOF())
        
        cXbanco:= ""
        
        IF (cTab)->BANCO$"341|001|033|104"
            cXbanco:=  Padr((cTab)->BANCO,TamSx3("EB_BANCO")[1])
        ELSE
            cXbanco:=  Padr("237",TamSx3("EB_BANCO")[1])
        ENDIF

        IF !EMPTY(cXbanco)
            //Posiciona no Contrato para obter a FORMA DE PAGAMENTO
            ZC0->(DbGoto((cTab)->RECZC0))
            ZC7->(DbGoto((cTab)->RECZC7))
            ZC8->(DbGoto((cTab)->RECZC8))
            SRD->(DbGoto((cTab)->RECSRD))   

            RECLOCK("ZC7",.F.)
            ZC7->ZC7_STATUS := "5"
            ZC7->(MSUNLOCK())           
            
            aOcorr:= StrTokArr(SRD->RD_XOCORRE, "|" ) 
            cOcorr:= ""
            cRet  := ""

            //Trata os codigos de Ocorrencia - (O Banco pode mandar ate 5 codigos de ocorrencia com 2 bytes cada concatenados)
            If len(aOcorr) > 0
                for nCont=1 to len(aOcorr)
                    cOcorr := AVKEY(aOcorr[nCont],"EB_REFBAN")   
                    SEB->(dbSetOrder(1))             
                    If SEB->(DBSEEK(XFILIAL("SEB")+cXbanco+cOcorr + "P" ))
                        cRet += ALLTRIM(aOcorr[nCont])+"-"+ALLTRIM(SEB->EB_DESCRI)+"/"
                    else
                        if !Empty(aOcorr[nCont])
                            cRet += ALLTRIM(aOcorr[nCont])+"-"+"Código de ocorrência não cadastrado/"
                        endif
                    endif
                next
            endif

            cDtaPag:= DTOS(SRD->RD_XDTEFET)
            cDtaPag:= Substr(cDtaPag,1,4) + "-" + Substr(cDtaPag,5,2) + "-" + Substr(cDtaPag,7,2)    

            cJson:= '{'
            cJson+= '  "sintetico": {'
            cJson+= '    "idcontrato": '+ EncodeUTF8(AllTrim(ZC7->ZC7_IDCNTT) , "cp1252") +',' 
            cJson+= '    "idlocalcontrato": '+ EncodeUTF8(AllTrim(ZC7->ZC7_IDLOCC) , "cp1252") +',' 
            cJson+= '    "competencia": "'+ EncodeUTF8(AllTrim(ZC7->ZC7_COMPET) , "cp1252") +'",' 
            cJson+= '    "idfolha": '+ EncodeUTF8(AllTrim(ZC8->ZC8_IDKAIR) , "cp1252") +',' 
            cJson+= '    "tipocalculo": '+ EncodeUTF8(AllTrim(ZC7->ZC7_TPCALC) , "cp1252") +','
            cJson+= '    "tipofolha": '+ EncodeUTF8(AllTrim(ZC7->ZC7_TPFOL) , "cp1252") +','
            cJson+= '    "quantidade": '+ EncodeUTF8(CVALTOCHAR(ZC7->ZC7_QUANT) , "cp1252") +','
            cJson+= '    "totalgeralpagar": '+ EncodeUTF8(CVALTOCHAR(ZC7->ZC7_TOTGER) , "cp1252") +','
            cJson+= '    "analitico": {'
            cJson+= '      "id": '+ EncodeUTF8(AllTrim(ZC8->ZC8_ID) , "cp1252") +','
            cJson+= '      "numerotce": '+ EncodeUTF8(AllTrim(ZC8->ZC8_NUMTCE) , "cp1252") +','
            cJson+= '      "situacaopagamento": '+ IIF(SRD->RD_XPROCBX == "2" ,"1" , "2")  +','
            cJson+= '      "formadepagamento": '+ EncodeUTF8(AllTrim(ZC0->ZC0_FORPGT) , "cp1252") +',' 
            cJson+= '      "datapagamento": " ' + EncodeUTF8(AllTrim(cDtaPag) , "cp1252") + '",'
            cJson+= '      "valorpagamento": ' + EncodeUTF8(CVALTOCHAR(SRD->RD_VALOR) , "cp1252") + ','
            cJson+= '      "ocorrencia": "'+ EncodeUTF8(AllTrim(cRet) , "cp1252") + '",'
            cJson+= '      "valorirrf": ' + EncodeUTF8(CVALTOCHAR((cTab)->VALORIRRF) , "cp1252") + ','
            cJson+= '      "dependentes": []'
            cJson+= '    }'
            cJson+= '  }'
            cJson+= '}'


            ZCQ->(RECLOCK("ZCQ",.T.))
            cIdLog:= "RP" + CVALTOCHAR(ZCQ->(RECNO()))
            ZCQ->ZCQ_FILIAL:= XFILIAL("ZCQ")
            ZCQ->ZCQ_TIPENV:= "RETORNO_PAGAMENTO_BOLSA"
            ZCQ->ZCQ_OPEENV:= "1" //POST
            ZCQ->ZCQ_IDENTI:= ZC8->ZC8_IDKAIR 
            ZCQ->ZCQ_URL   := ""
            ZCQ->ZCQ_IDLOG := cIdLog
            ZCQ->ZCQ_DTINTE:= DATE()
            ZCQ->ZCQ_HRINTE:= TIME()
            ZCQ->ZCQ_STATUS:= "0"
            ZCQ->ZCQ_FILA  := ALLTRIM(GetMV("CI_FRETPBA",.T.,"dev1-retorno-pagmento-bolsa-auxilio-kairos"))
            ZCQ->ZCQ_CODE  := ""
            ZCQ->ZCQ_JSON  := cJson
            ZCQ->(MSUNLOCK())    

            //Ajusta status para não enviar novamente
            IF SRD->RD_XPROCBX == "3"
                RecLock("SRD",.F.)
                    SRD->RD_XPROCBX := "6"
                SRD->(MsUnlock())                
            ENDIF

        ENDIF

        (cTab)->(dbSkip())

    End

    (cTab)->(dbcloseArea())

ENDIF


Return
/*/{Protheus.doc} DescalcBolsa 
Realizado o descalculo da bolsa
@type  Static Function
@author 
@since 04/11/2020
@version version
/*/
Static function DescalcBolsa()
Local cTInc:= GetNextAlias() 
Local cTMov:= ""

DbSelectarea("ZCV")
ZCV->(DbSetOrder(1))

BeginSql Alias cTInc
    SELECT ZC7.R_E_C_N_O_ AS RECZC7
          ,SRD.R_E_C_N_O_ AS RECSRD 
    FROM %Table:SRD% SRD  
    INNER JOIN %TABLE:ZC7% ZC7 ON ZC7_FILIAL=%xFilial:ZC7%
        AND ZC7_IDFOL=SRD.RD_XIDFOL
        AND ZC7.D_E_L_E_T_=' '    
    WHERE SRD.D_E_L_E_T_='' 
    AND SRD.RD_FILIAL = %xFilial:SRD% 
    AND SRD.RD_PD = 'J99'  
    AND SRD.RD_XSOCOR=%Exp:cXSeqOcor%   
    AND SRD.RD_XPROCBX IN ('4','6')  
EndSql

//GETLastQuery()[2]
While (cTInc)->(!EOF()) 

    ZC7->(DbGoto((cTInc)->RECZC7))
    SRD->(DbGoto((cTInc)->RECSRD))

    IF ZC7->(!EOF()) .AND. SRD->(!EOF())

        //Grava ocorrência para regularização        
        IF ZCV->(DbSeek(SRD->RD_FILIAL + SRD->RD_XIDFOL + SRD->RD_MAT))         
            RECLOCK("ZCV",.F.)
        ELSE
            RECLOCK("ZCV",.T.)
        ENDIF

        ZCV->ZCV_FILIAL := SRD->RD_FILIAL
        ZCV->ZCV_IDFOL  := SRD->RD_XIDFOL 
        ZCV->ZCV_MAT    := SRD->RD_MAT
        ZCV->ZCV_DATPGT := SRD->RD_DATPGT
        ZCV->ZCV_VALOR  := SRD->RD_VALOR 
        ZCV->ZCV_OCORRE := SRD->RD_XOCORRE
        ZCV->ZCV_SEQUEN := SRD->RD_XSOCOR
        ZCV->ZCV_NOME 	:= SRD->RD_XNOME
        ZCV->ZCV_IDCNT	:= SRD->RD_XIDCNT
        ZCV->ZCV_IDLOC	:= SRD->RD_XIDLOC
        ZCV->ZCV_NUMTIT	:= SRD->RD_XNUMTIT
        ZCV->ZCV_DTEFET	:= SRD->RD_XDTEFET        
        ZCV->ZCV_COMPET	:= RIGHT(ZC7->ZC7_COMPET,4) + LEFT(ZC7->ZC7_COMPET,2)
        ZCV->ZCV_STATUS := "1"
        ZCV->ZCV_MSGLOG := ""
        ZCV->ZCV_LOGCOM := ""
        ZCV->(MSUNLOCK())               
        
        cTMov:= GetNextAlias()

        BeginSql Alias cTMov
            SELECT R_E_C_N_O_ AS RECSRD FROM %Table:SRD% SRD  
            WHERE SRD.D_E_L_E_T_='' 
            AND SRD.RD_FILIAL = %xFilial:SRD% 
            AND SRD.RD_XIDFOL = %Exp:SRD->RD_XIDFOL%
            AND SRD.RD_MAT = %Exp:SRD->RD_MAT%   
        EndSql

        //GETLastQuery()[2]
        While (cTMov)->(!EOF()) 
            
            SRD->(DbGoto((cTMov)->RECSRD))
            IF SRD->(!EOF())
                RECLOCK("SRD",.F.)
                    DBDELETE()
                SRD->(MSUNLOCK())
            ENDIF

        (cTMov)->(dbSkip())
        End

        (cTMov)->(dbcloseArea())     
          
    ENDIF
    
(cTInc)->(dbSkip())
End

(cTInc)->(dbcloseArea())

Return
