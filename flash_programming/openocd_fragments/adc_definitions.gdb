# GDB Shortcut Commands

define adc1
  set print pretty on
  p /x *(ADC_TypeDef *)0x50040000
  set print pretty off
end
document adc1
  Pretty print the ADC1 register block at 0x50040000 in hex format
end

define adc1_isr
  set print pretty on
  p /x ((ADC_TypeDef *)0x50040000)->ISR
  set print pretty off
end
document adc1_isr
  Print ADC1->ISR in hex.
end

define adc1_dr
  set print pretty on
  p /x ((ADC_TypeDef *)0x50040000)->DR
  set print pretty off
end
document adc1_dr
  Print ADC1->ISR in hex.
end

define adcsum
printf "ADC1 Summary @ 0x50040000\n"

printf "  ISR   = "
p /x ((ADC_TypeDef *)0x50040000)->ISR
printf "          "
p /t ((ADC_TypeDef *)0x50040000)->ISR

printf "  IER   = "
p /x ((ADC_TypeDef *)0x50040000)->IER
printf "          "
p /t ((ADC_TypeDef *)0x50040000)->IER

printf "  DR    = "
p /x ((ADC_TypeDef *)0x50040000)->DR
printf "          "
p /t ((ADC_TypeDef *)0x50040000)->DR

printf "  SQR1  = "
p /x ((ADC_TypeDef *)0x50040000)->SQR1
printf "          "
p /t ((ADC_TypeDef *)0x50040000)->SQR1
end

document adcsum
kinda ugly - Print ADC1 ISR, IER, DR, and SQR1 in both hex and binary (using print /x and /t).
end


define adchex
  set print pretty on
  printf "ADC1 Summary @ 0x50040000\n"
  printf "  ISR   = 0x%08x\n", ((ADC_TypeDef *)0x50040000)->ISR
  printf "  IER   = 0x%08x\n", ((ADC_TypeDef *)0x50040000)->IER
  printf "  DR    = 0x%08x\n", ((ADC_TypeDef *)0x50040000)->DR
  printf "  SQR1  = 0x%08x\n", ((ADC_TypeDef *)0x50040000)->SQR1
  set print pretty off
end


define adc1_flags
  set $isr = ((ADC_TypeDef *)0x50040000)->ISR

  printf "ADC1->ISR = 0x%08x\n", $isr

  if ($isr & (1 << 2))
    printf "  EOC (End of Conversion)         = SET\n"
  else
    printf "  EOC (End of Conversion)         = CLEARED\n"
  end

  if ($isr & (1 << 3))
    printf "  EOS (End of Sequence)           = SET\n"
  else
    printf "  EOS (End of Sequence)           = CLEARED\n"
  end
end

document adc1_flags
  Inspect EOC and EOS bits in ADC1->ISR.
end