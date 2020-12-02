#INCLUDE "TOTVS.CH"

USER FUNCTION AJUSTRCJ()
Local cTZC1:= ""
Local cCodPro:= ""

IF TCSQLEXEC("DELETE "+RETSQLNAME("RCJ")) < 0
    U_uCONOUT(TCSQLERROR())
ELSE    
    cTZC1:= GetNextAlias()

    BeginSql Alias cTZC1
        SELECT * FROM %TABLE:ZC1% ZC1 
        WHERE ZC1_FILIAL=%xfilial:ZC1%
        AND ZC1.D_E_L_E_T_ =''
        ORDER BY R_E_C_N_O_	
    EndSql

    WHILE (cTZC1)->(!EOF())	

        cTRCJ:= GetNextAlias()
        BeginSql Alias cTRCJ
            SELECT MAX(RCJ_CODIGO) AS CODIGO FROM %TABLE:RCJ% RCJ 
            WHERE RCJ_FILIAL=%xfilial:RCJ%
            AND RCJ.D_E_L_E_T_ =''	
        EndSql    

        IF EMPTY((cTRCJ)->CODIGO)
            cCodPro:= "00001"
        ELSE
            cCodPro:= SOMA1((cTRCJ)->CODIGO)
        ENDIF     

        (cTRCJ)->(dbCloseArea())

        RCJ->(RecLock("RCJ", .T.))
            RCJ->RCJ_FILIAL := xFilial("RCJ")
            RCJ->RCJ_ORIGEM := "1"
            RCJ->RCJ_CODIGO := cCodPro
            RCJ->RCJ_DESCRI := (cTZC1)->ZC1_NOMFAN
            RCJ->RCJ_TPSAL  := ""
            RCJ->RCJ_TIVCV  := 0
            RCJ->RCJ_DIAPRO := 0
            RCJ->RCJ_MODULO := "GPE"
            RCJ->RCJ_IDCNTT := (cTZC1)->ZC1_CODIGO
            RCJ->RCJ_IDLOCC := (cTZC1)->ZC1_LOCCTR
        RCJ->(MsUnLock())

        IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRA")+" SET RA_PROCES='"+cCodPro+"'"+;
                    " WHERE RA_XIDCONT='"+(cTZC1)->ZC1_CODIGO+"'"+;
                    " AND RA_XIDLOCT='"+(cTZC1)->ZC1_LOCCTR+"'") < 0
            U_uCONOUT(TCSQLERROR())
        ENDIF   

    (cTZC1)->(dbSkip())
    end

    (cTZC1)->(dbCloseArea())


    msginfo("Concluido!!")


ENDIF   

Return