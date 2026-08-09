DELETE FROM Cevap
WHERE EXISTS (
    SELECT 1 FROM Soru s
    WHERE s.id=Cevap.soruID
    AND s.soranID=Cevap.cozenID
)