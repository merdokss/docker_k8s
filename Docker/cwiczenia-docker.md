### Ćwiczenie 1: Uruchamianie kontenera
1. Uruchom kontener z obrazem `nginx` w trybie odłączonym i nadaj mu nazwę `my_nginx`.
2. Sprawdź, czy kontener działa.
3. Zatrzymaj kontener `my_nginx`.

### Ćwiczenie 2: Praca z wolumenami
1. Utwórz nowy wolumen o nazwie `my_volume`.
2. Uruchom kontener z obrazem `nginx` i zamontuj wolumen `my_volume` do ścieżki `/usr/share/nginx/html` w kontenerze.
3. Sprawdź, czy wolumen został poprawnie zamontowany.

### Ćwiczenie 3: Zarządzanie obrazami
1. Pobierz obraz `alpine` z Docker Hub.
2. Utwórz nowy obraz na podstawie kontenera `alpine` z dodanym plikiem `hello.txt`.
3. Sprawdź, czy nowy obraz został utworzony.

### Ćwiczenie 4: Zarządzanie siecią
1. Utwórz nową sieć typu bridge o nazwie `my_bridge_network`.
2. Uruchom kontener `nginx` w nowo utworzonej sieci.
3. Sprawdź, czy kontener jest podłączony do sieci.
