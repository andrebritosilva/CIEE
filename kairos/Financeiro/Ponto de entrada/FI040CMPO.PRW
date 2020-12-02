#Include 'Protheus.ch'

USER FUNCTION FI040CMPO()
Local oOK   := LoadBitmap(GetResources(),'checkok') 
Local oNO   := LoadBitmap(GetResources(),'br_cancel')
Local oLeg  := NIL
Local cTab  := GetNextAlias()
Local cNoNum:= ""
Local cDescOc:= ""
Local aList := {}

RegToMemory("SE1", .F.)

cNoNum:= U_NossNum()

@ 083, 145 MSGET cNoNum When .F. SIZE 90, 9 OF PARAMIXB[1] PIXEL

BeginSql Alias cTab
    SELECT FI1_OCORS,
        FI1_OCORB,
        FI1_XMOTIV,
        FI1_XDESMO,
        FI0_ARQ,
        FI0_DTPRC,
        FI0_HRPRC,
        FI0_BCO,
        FI0_AGE,
        FI0_CTA,
        FI0_USU
    FROM %TABLE:FI1% FI1 
    INNER JOIN %TABLE:FI0% FI0 ON FI0_FILIAL=%xfilial:FI0%
        AND FI0_IDARQ= FI1_IDARQ
        AND FI0.D_E_L_E_T_ =' '
    WHERE  FI1_FILIAL=%xfilial:FI1%
    AND FI1_IDTIT=%Exp:SE1->E1_IDCNAB%
    AND FI1.D_E_L_E_T_ =' '
EndSql
//GETLASTQUERY()[2]

TCSETFIELD(cTab,"FI0_DTPRC","D")

WHILE (cTab)->(!EOF())	

    IF ALLTRIM((cTab)->FI1_OCORS)$"03"	
        oLeg:= oNO 
    ELSE
        oLeg:= oOK
    ENDIF

    AADD(aList,{ oLeg,;
                 (cTab)->FI1_OCORS,;
                 (cTab)->FI1_OCORB,;
                 cDescOc,;
                 (cTab)->FI1_XMOTIV,;
                 (cTab)->FI1_XDESMO,;
                 (cTab)->FI0_ARQ,;
                 (cTab)->FI0_DTPRC,;
                 (cTab)->FI0_HRPRC,;
                 (cTab)->FI0_BCO,;
                 (cTab)->FI0_AGE,;
                 (cTab)->FI0_CTA,;
                 (cTab)->FI0_USU})
(cTab)->(dbSkip())
end

(cTab)->(dbCloseArea())

IF EMPTY(aList)
    AADD(aList,{ '',;
                 '',;
                 '',;
                 '',;
                 '',;
                 '',;
                 '',;
                 '',;
                 '',;
                 '',;
                 '',;
                 '',;
                 ''})
ENDIF

@ 005,500 SAY "Log de Ocorrências" SIZE 70, 7 OF PARAMIXB[1] PIXEL 
oBrw2 := TCBrowse():New(013,500,(oSizeMain:GetDimension("SIZE2","XSIZE") / 2) - 50,(oSizeMain:GetDimension("SIZE2","YSIZE")) - 150 ,;
,{'','Ocorrência Sistema','Ocorrência Banco','Descrição Ocorrência','Motivo Banco','Descrição Motivo','Arquivo TXT','Data Processamento','Hora Processamento','Banco','Agência','Conta','Usuário'},,PARAMIXB[1],,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )

oBrw2:SetArray(aList)

oBrw2:bLine := {|oBrw2| { aList[oBrw2:NAT,01],;
                    aList[oBrw2:NAT,02],;
                    aList[oBrw2:NAT,03],;
                    aList[oBrw2:NAT,04],;
                    aList[oBrw2:NAT,05],;
                    aList[oBrw2:NAT,06],;
                    aList[oBrw2:NAT,07],;
                    aList[oBrw2:NAT,08],;
                    aList[oBrw2:NAT,09],;
                    aList[oBrw2:NAT,10],;
                    aList[oBrw2:NAT,11],;
                    aList[oBrw2:NAT,12],;
                    aList[oBrw2:NAT,13] } }              

RETURN 
