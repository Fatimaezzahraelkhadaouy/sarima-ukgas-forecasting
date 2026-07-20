# INSTALLATION DES PACKAGES

install.packages("tseries")
install.packages("zoo")
install.packages("forecast")
install.packages("lmtest")
install.packages("randtests")


# CHARGEMENT DES BIBLIOTHEQUES

library(tseries)
library(zoo)
library(forecast)
library(lmtest)
library(randtests)

# CHARGEMENT DES DONNEES

data("UKgas")

# INFORMATIONS SUR LA SERIE

cat("Debut        :", start(UKgas), "\n")
cat("Fin          :", end(UKgas), "\n")
cat("Frequence    :", frequency(UKgas), "\n")
cat("Observations :", length(UKgas), "\n")
summary(UKgas)

# CREATION DE LA SERIE TEMPORELLE

ukgas.ts <- ts(UKgas, start = c(1960, 1), frequency = 4)

# DATATION DE LA SERIE

D <- as.Date(as.yearmon(time(ukgas.ts)))
ukgas.df <- data.frame(Date  = D,
                       Valeur = as.numeric(ukgas.ts))

# Premieres et dernieres observations
ukgas.apercu <- rbind(head(ukgas.df, 4), tail(ukgas.df, 4))
print(ukgas.apercu, row.names = FALSE)

# DIVISION 80% APPRENTISSAGE / 20% VALIDATION

n       <- length(ukgas.ts)
n_train <- round(0.8 * n)
n_test  <- n - n_train

train <- window(ukgas.ts, end   = time(ukgas.ts)[n_train])
test  <- window(ukgas.ts, start = time(ukgas.ts)[n_train + 1])

cat("Nombre total d observations :", n,              "\n")
cat("Ensemble apprentissage       :", length(train), "\n")
cat("Ensemble validation          :", length(test),  "\n")
cat("Debut apprentissage :", start(train), "\n")
cat("Fin apprentissage   :", end(train),   "\n")
cat("Debut validation    :", start(test),  "\n")
cat("Fin validation      :", end(test),    "\n")


# REPRESENTATION GRAPHIQUE

png("ukgas_brut.png", width = 800, height = 500)
plot(ukgas.ts, type = "l", col = "green",
     main = "Consommation de gaz au Royaume-Uni (1960-1986)",
     xlab = "Temps",
     ylab = "Consommation (millions de therms)")
dev.off()

# ACF ET PACF DE LA SERIE BRUTE


# ACF
png("acf_ukgas.png", width = 800, height = 500)
plot(acf(as.numeric(ukgas.ts), lag.max = 36, plot = FALSE),
     ylim = c(-1, 1),
     main = "ACF de la série UKgas brute")
dev.off()

# PACF
png("pacf_ukgas.png", width = 800, height = 500)
plot(pacf(as.numeric(ukgas.ts), lag.max = 36, plot = FALSE),
     ylim = c(-1, 1),
     main = "PACF de la série UKgas brute")
dev.off()

# TEST DE FISHER (ANOVA) TENDANCE ET SAISONNALITE

x <- as.numeric(ukgas.ts)
N <- 27    # nombre d annees (1960-1986)
p <- 4     # trimestres par an

annee   <- rep(1:N, each = p)[1:length(x)]
periode <- rep(1:p, times = N)[1:length(x)]

ukgas.anova <- data.frame(
  valeur  = x,
  annee   = as.factor(annee),
  periode = as.factor(periode)
)

model.anova <- aov(valeur ~ annee + periode, data = ukgas.anova)
summary(model.anova)
# ACF avec lag plus grand pour detecter la saisonnalite
png("acf_ukgas_saisonnalite.png", width = 800, height = 500)
plot(acf(as.numeric(ukgas.ts), lag.max = 48, plot = FALSE),
     ylim = c(-1, 1),
     main = "ACF de la série UKgas - Détection de la saisonnalité")
dev.off()

# PACF avec lag plus grand
png("pacf_ukgas_saisonnalite.png", width = 800, height = 500)
plot(pacf(as.numeric(ukgas.ts), lag.max = 48, plot = FALSE),
     ylim = c(-1, 1),
     main = "PACF de la série UKgas - Détection de la saisonnalité")
dev.off()
# CHAPITRE 4 : TEST DE STATIONNARITE
# SUR LA SERIE D APPRENTISSAGE


# ACF serie d apprentissage
png("acf_train_ukgas.png", width = 800, height = 500)
plot(acf(as.numeric(train), lag.max = 36, plot = FALSE),
     ylim = c(-1, 1),
     main = "ACF de la série d'apprentissage UKgas")
dev.off()

# PACF serie d apprentissage
png("pacf_train_ukgas.png", width = 800, height = 500)
plot(pacf(as.numeric(train), lag.max = 36, plot = FALSE),
     ylim = c(-1, 1),
     main = "PACF de la série d'apprentissage UKgas")
dev.off()

# Test ADF
adf.test(train)

# Test KPSS
kpss.test(train)

# CHAPITRE 5 : STATIONNARISATION DE LA SERIE

# Transformation logarithmique
train_log <- log(train)

# Visualisation serie log
png("ukgas_train_log.png", width = 800, height = 500)
plot(train_log, type = "l", col = "green",
     main = "Série d'apprentissage UKgas après transformation log",
     xlab = "Temps",
     ylab = "log(UKgas)")
dev.off()

# Differenciation d ordre 1 (tendance)
train_log_diff1 <- diff(train_log, differences = 1)

# Differenciation saisonniere d ordre 1 (saisonnalite)
train_log_diff1_4 <- diff(train_log_diff1, lag = 4, differences = 1)

# Visualisation serie stationnaire
png("ukgas_stationnaire.png", width = 800, height = 500)
plot(train_log_diff1_4, type = "l", col = "green",
     main = "Série UKgas après transformation log et double différenciation",
     xlab = "Temps",
     ylab = "Valeur")
dev.off()

# ACF et PACF serie stationnaire
png("acf_ukgas_stat.png", width = 800, height = 500)
plot(acf(as.numeric(train_log_diff1_4), lag.max = 36, plot = FALSE),
     ylim = c(-1, 1),
     main = "ACF de la série UKgas stationnaire")
dev.off()

png("pacf_ukgas_stat.png", width = 800, height = 500)
plot(pacf(as.numeric(train_log_diff1_4), lag.max = 36, plot = FALSE),
     ylim = c(-1, 1),
     main = "PACF de la série UKgas stationnaire")
dev.off()

# Test ADF
adf.test(train_log_diff1_4)

# Test KPSS
kpss.test(train_log_diff1_4)

# CHAPITRE 6 : IDENTIFICATION DU MODELE

# Test de Bartlet
T <- length(train_log_diff1_4)
borne <- 2 / sqrt(T)
cat("Borne de Bartlet :", borne, "\n")

acf_vals  <- acf(as.numeric(train_log_diff1_4), 
                 lag.max = 36, plot = FALSE)
pacf_vals <- pacf(as.numeric(train_log_diff1_4), 
                  lag.max = 36, plot = FALSE)

# Lags significatifs
cat("Lags ACF significatifs :\n")
print(which(abs(acf_vals$acf) > borne))

cat("Lags PACF significatifs :\n")
print(which(abs(pacf_vals$acf) > borne)) 

# CHAPITRE 7 : ESTIMATION DES MODELES

# Modele 1 : SARIMA(1,1,1)(1,1,1)[4]
model1 <- Arima(train_log, order = c(1,1,1),
                seasonal = list(order = c(1,1,1), period = 4))
coeftest(model1)
cat("AIC model1 :", AIC(model1), "\n")
cat("BIC model1 :", BIC(model1), "\n\n")

# Modele 2 : SARIMA(2,1,1)(1,1,1)[4]
model2 <- Arima(train_log, order = c(2,1,1),
                seasonal = list(order = c(1,1,1), period = 4))
coeftest(model2)
cat("AIC model2 :", AIC(model2), "\n")
cat("BIC model2 :", BIC(model2), "\n\n")

# Modele 3 : SARIMA(1,1,2)(1,1,1)[4]
model3 <- Arima(train_log, order = c(1,1,2),
                seasonal = list(order = c(1,1,1), period = 4))
coeftest(model3)
cat("AIC model3 :", AIC(model3), "\n")
cat("BIC model3 :", BIC(model3), "\n\n")

# Modele 4 : SARIMA(2,1,2)(1,1,1)[4]
model4 <- Arima(train_log, order = c(2,1,2),
                seasonal = list(order = c(1,1,1), period = 4))
coeftest(model4)
cat("AIC model4 :", AIC(model4), "\n")
cat("BIC model4 :", BIC(model4), "\n\n")

# Modele 5 : SARIMA(0,1,1)(0,1,1)[4]
model5 <- Arima(train_log, order = c(0,1,1),
                seasonal = list(order = c(0,1,1), period = 4))
coeftest(model5)
cat("AIC model5 :", AIC(model5), "\n")
cat("BIC model5 :", BIC(model5), "\n\n")

# Modele 6 : SARIMA(1,1,1)(0,1,1)[4]
model6 <- Arima(train_log, order = c(1,1,1),
                seasonal = list(order = c(0,1,1), period = 4))
coeftest(model6)
cat("AIC model6 :", AIC(model6), "\n")
cat("BIC model6 :", BIC(model6), "\n\n")

# Modele 7 : SARIMA(0,1,2)(0,1,1)[4]
model7 <- Arima(train_log, order = c(0,1,2),
                seasonal = list(order = c(0,1,1), period = 4))
coeftest(model7)
cat("AIC model7 :", AIC(model7), "\n")
cat("BIC model7 :", BIC(model7), "\n\n")

# CHAPITRE 8 : VALIDATION DES MODELES

# ---- MODELE 5 : SARIMA(0,1,1)(0,1,1)[4] ----

residus5 <- residuals(model5)

# Graphique des residus
png("residus5.png", width = 800, height = 500)
plot(residus5, type = "l", col = "green",
     main = "Résidus du modèle SARIMA(0,1,1)(0,1,1)[4]",
     xlab = "Temps", ylab = "Résidus")
dev.off()

# ACF des residus
png("acf_residus5.png", width = 800, height = 500)
acf(as.numeric(residus5), lag.max = 36,
    main = "ACF des résidus SARIMA(0,1,1)(0,1,1)[4]")
dev.off()

# Test de Box-Pierce
Box.test(residus5, type = "Box-Pierce", lag = 20)

# Test de Ljung-Box
Box.test(residus5, type = "Ljung-Box", lag = 20)

# Test de Shapiro-Wilk
shapiro.test(as.numeric(residus5))

# QQ-plot
png("qqplot_residus5.png", width = 800, height = 500)
qqnorm(as.numeric(residus5),
       main = "QQ-plot des résidus SARIMA(0,1,1)(0,1,1)[4]")
qqline(as.numeric(residus5), col = "green")
dev.off()

# ---- MODELE 7 : SARIMA(0,1,2)(0,1,1)[4] ----

residus7 <- residuals(model7)

# Graphique des residus
png("residus7.png", width = 800, height = 500)
plot(residus7, type = "l", col = "green",
     main = "Résidus du modèle SARIMA(0,1,2)(0,1,1)[4]",
     xlab = "Temps", ylab = "Résidus")
dev.off()

# ACF des residus
png("acf_residus7.png", width = 800, height = 500)
acf(as.numeric(residus7), lag.max = 36,
    main = "ACF des résidus SARIMA(0,1,2)(0,1,1)[4]")
dev.off()

# Test de Box-Pierce
Box.test(residus7, type = "Box-Pierce", lag = 20)

# Test de Ljung-Box
Box.test(residus7, type = "Ljung-Box", lag = 20)

# Test de Shapiro-Wilk
shapiro.test(as.numeric(residus7))

# QQ-plot
png("qqplot_residus7.png", width = 800, height = 500)
qqnorm(as.numeric(residus7),
       main = "QQ-plot des résidus SARIMA(0,1,2)(0,1,1)[4]")
qqline(as.numeric(residus7), col = "green")
dev.off()
# CHAPITRE 9 : PREVISION


# Nombre de periodes a prevoir
h <- length(test)
cat("Nombre de periodes a prevoir :", h, "\n")

# Prevision sur la serie log
prev7 <- forecast(model7, h = h)

# Graphique previsions sur serie log
png("prevision_ukgas_log.png", width = 800, height = 500)
plot(prev7,
     main = "Prevision de la consommation de gaz UKgas log",
     xlab = "Temps",
     ylab = "log(UKgas)")
dev.off()

# Retransformation en valeurs originales
prev7_orig <- exp(prev7$mean)
test_orig  <- as.numeric(test)

# Graphique previsions vs valeurs reelles
png("prevision_ukgas_orig.png", width = 800, height = 500)
plot(test_orig, type = "l", col = "black",
     main = "Prévision vs Valeurs réelles UKgas",
     xlab = "Temps",
     ylab = "Consommation (millions de therms)",
     ylim = range(c(test_orig, as.numeric(prev7_orig))))
lines(as.numeric(prev7_orig), col = "green", lwd = 2)
legend("topleft",
       legend = c("Valeurs réelles", "Prévisions"),
       col = c("black", "green"),
       lwd = 2)
dev.off()

# Calcul des erreurs
rmse <- sqrt(mean((test_orig - as.numeric(prev7_orig))^2))
mape <- mean(abs((test_orig - as.numeric(prev7_orig)) /
                   test_orig)) * 100
cat("RMSE :", rmse, "\n")
cat("MAPE :", mape, "%\n")