# Calgary–Banff Stated Preference Design

An R script that generates a D-efficient stated preference (SP) experimental design for a Calgary–Banff mode choice survey (Car, Bus, Rail), using the [spdesign](https://spdesign.edsandorf.me) package. Priors are taken from the Swissmetro MNL model (Bierlaire, Axhausen & Abay, 2001, Table 2).

## Design summary

| Item | Value |
|---|---|
| Model | Multinomial logit (MNL) |
| Efficiency criterion | D-error |
| Algorithm | Federov |
| Choice tasks | 18, blocked into 2 versions of 9 |
| Alternatives | Car, Bus (reference), Rail |

**Attributes and levels** (one-way, CAD):

| Mode | Travel time (min) | Cost ($) | Headway (min) |
|---|---|---|---|
| Car | 80, 100, 120 | 20, 35, 50 | n/a |
| Bus | 100, 115, 130 | 15, 25, 35 | 60, 90, 120 |
| Rail | 75, 90, 105 | 20, 35, 50 | 30, 60, 90 |

**Priors** (Swissmetro Table 2; cost converted at 1 CHF = 1.711 CAD):

| Parameter | Prior |
|---|---|
| ASC car | 1.108 |
| ASC rail | 1.302 |
| Travel time (per min) | −0.0126 |
| Cost (per CAD) | −0.0061 |
| Headway (per min) | −0.0026 |

Exclusions remove tasks where one mode is better on every attribute. Each attribute level appears 5–7 times.

## Requirements

- R (4.x)
- `spdesign` from CRAN

```r
install.packages("spdesign")
```

## Usage

```bash
Rscript banff_design.R
```

Or open `banff_design.R` in RStudio and click **Source**. The run takes about 8–9 minutes. `set.seed(2026)` makes the result reproducible.

## Output

- `banff_design.csv`: the 18 choice tasks (one row per task) with a `block` column for the survey version.
- Console: the search log, the design's A-, D- and S-errors, the block correlation check, and predicted choice shares for each task under the priors.

Reference run: D-error 0.00576, S-error 124 (about 250 respondents minimum across 2 blocks).

## References

- Bierlaire, M., Axhausen, K.W. & Abay, G. (2001). *The acceptance of modal innovation: The case of Swissmetro.* 1st Swiss Transport Research Conference, Ascona.
- Bliemer, M.C.J. & Rose, J.M. *Designing and conducting stated choice experiments.* In Hess, S. & Daly, A. (eds), *Handbook of Choice Modelling*, 2nd ed.
- Sandorf, E.D. & Campbell, D. *spdesign: Designing Stated Preference Experiments.* R package. https://spdesign.edsandorf.me
