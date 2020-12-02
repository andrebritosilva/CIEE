#Include 'Protheus.ch'
#include "TopConn.ch"

Static lValidBco:= .T.

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} F430VAR
Tem como finalidade tratar os dados para baixa CNAB. Antes de verificar a especie
do titulo o array aValores permitira que qualquer excecao ou necessidade seja tratada
no ponto de entrada em PARAMIXB.
@author  	Felipe Queiroz
@since     	20/04/2016
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function F430VAR()
Local _aAreaSE2:= GetArea()    
Local _IdentBA := AllTrim(GetNewPar("CI_IDENBA","BA"))
Local _cBanco  := ""
PRIVATE dXDtbaix:= ParamIxb[01,02] //	data da Baixa		- 02
PRIVATE cLinhaIn:= ParamIxb[01,16] // Linha Inteira	- 16

_cBanco := LEFT(cLinhaIn,3)

If EMPTY(_cBanco)
   RETURN
ENDIF

IF _cBanco$"237|341|033|001" .AND. SUBSTR(cLinhaIn,074,2) == _IdentBA 
   
   RetKairos(_cBanco,;
             SUBSTR(cLinhaIn,76,3),;
             SUBSTR(cLinhaIn,231,10)) //ParamIxb[1,12])
   
   cNumTit:= "" //Tratamento para realizar loop

ElseIF _cBanco == "104" .AND. SUBSTR(cLinhaIn,178,2) == _IdentBA     //Caixa - Posição Cnab INFORMACAO 2       178-217

   RetKairos(_cBanco,;
             SUBSTR(cLinhaIn,180,3),;
             ParamIxb[1,12])   

   cNumTit:= "" //Tratamento para realizar loop

ELSEIF LEFT(cNumTit,2) == _IdentBA
   cNumTit:= "" //Tratamento para realizar loop
ELSE
   If !Empty(cNumTit)

      //Busca por IdCnab (sem filial)
      SE2->(dbSetOrder(13)) // IdCnab
      SE2->(MsSeek(Substr(cNumTit,1,10)))
         If ALLTRIM(SE2->E2_XSTSAPV) == '1'
               MsgAlert("Titulo aguardando aprovação do bordero de pagamentos, verificar com os aprovadores "+SE2->E2_NUMBOR+"!!!",SE2->E2_PREFIXO+" "+SE2->E2_NUM)
               cNumTit = ''
         EndIf		
   EndIf
ENDIF

RestArea(_aAreaSE2)	

Return()

/*/{Protheus.doc} RetKairos
Rotina de atualização dos retorno de CNAB Kairós (Pagamento de bolsa e 1 centavo)
@type  Static Function
@author Carlos Henrique
@since 15/05/2020 - Retomada da customização em 26/06/2020 (Luiz Enrique)
@version version
/*/
Static Function RetKairos(_cBanco , _cTab, _cOcorr)

Local _cChave     := ""
Local cCodOcor    := Alltrim(_cOcorr)
Local cProcBaixa  := "1"
Local nTam        := 0
Local nx          := 0
Local cNewCodOcor := ""
Local cXbanco     := ""
Local cAtivo      := "N"
Local cXSeqOcor   := ""
Local cTabSRD     := ""

IF lValidBco
   
   lValidBco:= .F.

   IF TRIM(_cBanco) != TRIM(MV_PAR05)
      MSGALERT("O banco selecionado "+ MV_PAR05 +" é diferente do arquivo: "+_cBanco)
   ENDIF

ENDIF

IF TRIM(_cBanco) == TRIM(MV_PAR05)

   //Monta codigo da ocorrencia com separadores (|) para diferenciar os códigos e gravar na SRD.
   nTam:= Len(cCodOcor)
   cNewCodOcor:= ""
   For nx:= 1 to nTam Step 2
      cNewCodOcor+= substr(cCodOcor,nx,2) + "|"
   Next

   //Verifica se código de Ocorrencia indica uma operação Válida oriunda do Banco.   
   If LEN(cNewCodOcor) == 3   //Se o tamanho for maior que 3, indica que existe codigo de ocorrencia de invalidade da operação.

      IF RIGHT(cNewCodOcor,1)=="|"
         cNewCodOcor:= LEFT(cNewCodOcor,LEN(cNewCodOcor)-1)
      ENDIF

      ccdOc:= LEFT( cNewCodOcor, 2 )
      SEB->(dbSetOrder(1))
      cXbanco:=  Padr(_cBanco,TamSx3("EB_BANCO")[1])
      ccdOc  :=  Padr(ccdOc,TamSx3("EB_REFBAN")[1])
      IF SEB->(DbSeek(xFilial("SEB") + cXbanco + ccdOc + "P"))

         IF ( SEB->EB_OCORR $ "01|06|07|08" )   //Baixa do Titulo
            cProcBaixa:= "1"  //Ocorrencia Valida,Pendente da Baixa do Titulo que será realizada pelo Ponto de Entrada: F430COMP.PRW
            cAtivo:= "S"      
         ELSEIF ( SEB->EB_OCORR $ "02" )        //Entrada confirmada
            cProcBaixa:= "5"  //Agendamento
            cAtivo:= "S"         
         ELSEIF ( SEB->EB_OCORR $ "03" )        //Entrada rejeitada
            cProcBaixa:= "3"  //Ooorrencia Invalida, Baixa não sera realizada.     
         ENDIF

      ELSE
         cProcBaixa:= "X"  //Ooorrencia Invalida, Baixa não sera realizada. Codigo inexistente na SEB 
      ENDIF
   ELSE
      cProcBaixa:= "3"  //Ooorrencia Invalida, Baixa não sera realizada.  
   ENDIF

   //Tratamento para pegar a chave de retorno
   IF _cBanco$"237|341|033|001" 

      _cChave:= SUBSTR(cLinhaIn,79,15)

   ELSEIF _cBanco == "104"

      _cChave:= SUBSTR(cLinhaIn,183,15)

   ENDIF 

   
   IF _cTab == "SRA"

      cXSeqOcor:= U_CSEQRET("A")

      dbselectArea("SRA")
      //Tratamento para pegar o id do estudante
      SRA->(DbOrderNickName("IDTCETCA01"))
      if SRA->(DbSeek(xFilial("SRA") + _cChave ))

         IF EMPTY(SRA->RA_XPROCBX)  .OR.  SRA->RA_XPROCBX == '5'
            RecLock("SRA",.F.)
               RA_XOCOREN:= cNewCodOcor 
               RA_XATIVO:= cAtivo
               RA_XSOCOR:= cXSeqOcor  
               RA_XSTATOC:= "2"
               If cProcBaixa == "3"
                  RA_XSTATOC:= "1"            
               Elseif !Empty(dXDtbaix)
                  RA_XDTEFET:= dXDtbaix //Dtos(dXDtbaix) 
               Endif
               SRA->RA_XPROCBX = cProcBaixa 
            MsUnLock()
         ENDIF

      endif	  

   ELSEIF _cTab == "SRQ"
      
      cXSeqOcor:= U_CSEQRET("B")

      dbselectArea("SRQ")
      SRQ->(DbOrderNickName("IDTCETCA03"))
      if SRQ->(DbSeek(xFilial("SRQ") + _cChave ))
         
         IF EMPTY(SRQ->RQ_XPROCBX)  .OR.  SRQ->RQ_XPROCBX == '5'
            RecLock("SRQ",.F.)
               RQ_XOCOREN:= cNewCodOcor 
               RQ_XATIVO:= cAtivo
               RQ_XSOCOR:= cXSeqOcor   
               RQ_XSTATOC:= "2"
               If cProcBaixa == "3"
                  RQ_XSTATOC:= "1"            
               Elseif !Empty(dXDtbaix)
                  RQ_XDTEFET:= dXDtbaix //Dtos(dXDtbaix) 
               Endif
               SRQ->RQ_XPROCBX = cProcBaixa 
            MsUnLock()
         ENDIF

      endif	    

   ELSEIF _cTab == "SRD" 

      cXSeqOcor:= U_CSEQRET("C")
   
      //A partir de 16/06/2020 a Tabela SRD tera o Campo(RD_XOCORRE) com 15 caracteres para gravar os Codigos das Ocorrencias.
      //São definidos pela FEBRABAN, 2 bytes por codigo de ocorrencia, podendo ser recebidos até 5 codigos que serão separados por (|) no
      //campo RD_XOCORRE da SRD

      cTabSRD:= GetNextAlias() 
      BeginSql Alias cTabSRD
         SELECT SRD.R_E_C_N_O_ AS RECNOSRD       
         FROM %Table:SRD% SRD  
         WHERE SRD.D_E_L_E_T_='' 
         AND RD_FILIAL = %xFilial:SRD% 
         AND RD_XNUMDOC = %EXP:_cChave% 
         AND (RD_XPROCBX = '' OR  RD_XPROCBX = '5')
      EndSql

      If (cTabSRD)->(!EOF())

         //Atualiza a SRD
         SRD->(DBGOTO((cTabSRD)->RECNOSRD))
         
         SRD->(RECLOCK("SRD",.F.))
         SRD->RD_XOCORRE = cNewCodOcor 
         SRD->RD_XPROCBX = cProcBaixa 
         SRD->RD_XDTEFET = IIF(!Empty(dXDtbaix),dXDtbaix,CTOD(""))
         SRD->RD_XSOCOR  = cXSeqOcor 		
         SRD->(msUnLock())

         //Posiciona na SRA ou SRQ e Grava Status de bloqueio no caso de inconsistencia ou Data de Baixa caso não houver inconsistencias
         //-----------------------------------------------------------------------------------------------------------------------
         If SRD->RD_PD == 'J99'            //LIQUIDO A RECEBER  - ESTUDANTE
            dbselectArea("SRA")
            SRA->(dbSetOrder(1))
            If SRA->(DbSeek(xFilial("SRA") + SRD->RD_MAT ))
               if SRA->(RECLOCK("SRA",.F.))
                  If cProcBaixa == "3"
                     SRA->RA_XSTATOC:= "1"
                  Elseif !Empty(dXDtbaix)
                     SRA->RA_XDTEFET:= dXDtbaix
                  Endif

               else
                  msgAlert("Falha ao atualizar registro")
               endif
               SRA->(msUnLock())
            Endif
         ElseIf SRD->RD_PD == '554'    //PENSAO ALIM FOLHA - BENEFICIARIO
               SRQ->(dbSetOrder(2))
               If SRQ->(DbSeek(xFilial("SRQ") + SRD->RD_XIDBEN ))
                  SRQ->(RECLOCK("SRQ",.F.))
                  If cProcBaixa == "3"
                     RQ_XSTATOC:= "1"
                  Elseif !Empty(dXDtbaix)
                     RQ_XDTEFET:= dXDtbaix
                  Endif
                  SRQ->(msUnLock())
               Endif
         Endif
         //------------------------------------------------------------------------------------------------------------------------

      Endif

      (cTabSRD)->(dbcloseArea())

   ENDIF
   
ENDIF
  
Return
