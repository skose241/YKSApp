<!DOCTYPE HTML>
<html lang="tr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width,initial-scale=1.0">

        <title>YKS Soru&Çözüm Platformu</title>

        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
        <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">
        <link href="/YKSSite/assets/css/style.css" rel="stylesheet">
    </head>

    <body>
        <cfset oturumVar=structKeyExists(SESSION,"kullaniciID") AND val(SESSION.kullaniciID) GT 0>

        <cfif oturumVar>
            <cfquery name="qOkunmamis" datasource="DSN">
                SELECT COUNT(*) AS adet
                FROM Bildirim
                WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
                AND goruldu=0
            </cfquery>
        </cfif>

        <cfoutput>
            <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
                <div class="container">
                    <a class="navbar-brand fw-bold" href="/YKSSite/index.cfm">
                        <i class="bi bi-mortarboard-fill"></i>YKS Platform
                    </a>

                    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="##navMenu">
                        <span class="navbar-toggler-icon"></span>
                    </button>

                    <div class="collapse navbar-collapse" id="navMenu">
                        <cfif NOT oturumVar>
                            <ul class="navbar-nav ms-auto">
                                <li class="nav-item">
                                    <a class="nav-link" href="/YKSSite/views/kimlik/giris.cfm">
                                        <i class="bi bi-box-arrow-in-right"></i>Giriş Yap
                                    </a>
                                </li>

                                <li class="nav-item">
                                    <a class="nav-link" href="/YKSSite/views/kimlik/kayit.cfm">
                                        <i class="bi bi-person-plus"></i>Kayıt Ol
                                    </a>
                                </li>
                            </ul>
                        <cfelse>
                            <ul class="navbar-nav me-auto">
                                <li class="nav-item">
                                    <a class="nav-link" href="/YKSSite/anaSayfa.cfm">
                                        <i class="bi bi-house"></i>Ana Sayfa
                                    </a>
                                </li>

                                <li class="nav-item">
                                    <a class="nav-link" href="/YKSSite/views/soru/soruEkle.cfm">
                                        <i class="bi bi-plus-circle"></i>Soru Ekle
                                    </a>
                                </li>
                            </ul>

                            <ul class="navbar-nav ms-auto align-items-center">
                                <li class="nav-item me-3">
                                    <span class="badge bg-warning text-dark">
                                        <i class="bi bi-star-fill"></i>#val(SESSION.xp)# XP
                                    </span>
                                </li>

                                <li class="nav-item me-2">
                                    <a class="nav-link position-relative" href="/YKSSite/views/bildirim/bildirimler.cfm">
                                        <i class="bi bi-bell"></i>

                                        <cfif qOkunmamis.adet GT 0>
                                            <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">
                                                #qOkunmamis.adet#
                                            </span>
                                        </cfif>
                                    </a>
                                </li>

                                <li class="nav-item dropdown">
                                    <a class="nav-link dropdown-toggle d-flex align-items-center gap-2" href="##" role="button" data-bs-toggle="dropdown">
                                        <img src="#application.avatarURL##urlEncodedFormat(SESSION.kullaniciAd)#"
                                            class="rounded-circle" width="32" height="32" alt="">
                                        <span class="d-none d-lg-inline">#encodeForHTML(SESSION.kullaniciAd)#</span>
                                    </a>

                                    <ul class="dropdown-menu dropdown-menu-end">
                                        <li>
                                            <a class="dropdown-item" href="/YKSSite/views/profil/profilim.cfm">
                                                <i class="bi bi-person"></i>Profilim
                                            </a>
                                        </li>

                                        <li>
                                            <a class="dropdown-item" href="/YKSSite/views/profil/liderlikTablosu.cfm">
                                                <i class="bi bi-trophy"></i>Liderlik Tablosu
                                            </a>
                                        </li>

                                        <cfif val(SESSION.rol) GTE 2>
                                            <li><hr class="dropdown-divider"></li>

                                            <li>
                                                <a class="dropdown-item text-warning" href="/YKSSite/views/yonetim/panel.cfm">
                                                    <i class="bi bi-shield"></i>Yönetim Paneli
                                                </a>
                                            </li>
                                        </cfif>

                                        <li><hr class="dropdown-divider"></li>

                                        <li>
                                            <a class="dropdown-item text-danger" href="/YKSSite/views/kimlik/cikis.cfm">
                                                <i class="bi bi-box-arrow-right"></i>Çıkış Yap
                                            </a>
                                        </li>
                                    </ul>
                                </li>
                            </ul>
                        </cfif>
                    </div>
                </div>
            </nav>
        </cfoutput>