#INCLUDE "TOTVS.CH"

USER FUNCTION GERAZCS()
Local cTZCQ:= ""

IF MSGYESNO("Confirma a limpeza da tabela ZCS e refazer de acordo com a ZCQ?")

    IF TCSQLEXEC("DELETE "+RETSQLNAME("ZCS")) < 0
        MSGALERT(TCSQLERROR())
    ELSE
        cTZCQ:= GetNextAlias()
        BeginSql Alias cTZCQ
            SELECT ZCQ.R_E_C_N_O_ AS RECZCQ
                  ,ZCP_FILDW3 
            FROM %TABLE:ZCQ% ZCQ
            INNER JOIN %TABLE:ZCP% ZCP ON ZCP_FILA=ZCQ_FILA
                AND ZCP_ENVDW3='1'
                AND ZCP.D_E_L_E_T_=''
            WHERE ZCQ_FILIAL=%xfilial:ZCQ%
            AND ZCQ.D_E_L_E_T_ =''
            ORDER BY ZCQ.R_E_C_N_O_	
        EndSql

        WHILE (cTZCQ)->(!EOF())	

            ZCQ->(DBGOTO((cTZCQ)->RECZCQ))
            IF ZCQ->(!EOF())

                RECLOCK("ZCS",.T.)
                    ZCS->ZCS_FILIAL:= ZCQ->ZCQ_FILIAL
                    ZCS->ZCS_TIPENV:= ZCQ->ZCQ_TIPENV 
                    ZCS->ZCS_OPEENV:= ZCQ->ZCQ_OPEENV
                    ZCS->ZCS_IDENTI:= ZCQ->ZCQ_IDENTI
                    ZCS->ZCS_URL   := ZCQ->ZCQ_URL
                    ZCS->ZCS_IDLOG := ZCQ->ZCQ_IDLOG
                    ZCS->ZCS_DTINTE:= ZCQ->ZCQ_DTINTE
                    ZCS->ZCS_HRINTE:= ZCQ->ZCQ_HRINTE
                    ZCS->ZCS_STATUS:= "0"
                    ZCS->ZCS_FILA  := (cTZCQ)->ZCP_FILDW3 
                    ZCS->ZCS_CODE  := "" 
                    ZCS->ZCS_JSON  := ZCQ->ZCQ_JSON
                MSUNLOCK()   
            
            ENDIF

        (cTZCQ)->(dbSkip())
        end

        (cTZCQ)->(dbCloseArea())

        msginfo("Concluido!!")

    ENDIF
ENDIF

Return
