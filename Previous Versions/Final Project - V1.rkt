;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname |Final Project|) (read-case-sensitive #t) (teachpacks ((lib "image.rkt" "teachpack" "2htdp") (lib "universe.rkt" "teachpack" "2htdp"))) (htdp-settings #(#t constructor repeating-decimal #t #t none #f ((lib "image.rkt" "teachpack" "2htdp") (lib "universe.rkt" "teachpack" "2htdp")) #f)))
(require racket/list)
(require 2htdp/batch-io)
(require 2htdp/image)

; Worldstate structure
; * player - a structure containing information directly related to the player character
; * keys - list of key structures
; * lod - a list where each member is a Door structure
; * low - a list of walls for the current level
; * level - a number representing the level the character is on
; * points - the number of points the character has (may not use this)
(define-struct WS [player keys lod low level points])

; Player structure: all fields directly related to the player character
; * pos - a posn with the (x y) location of the player
; * lives - number of remaining lives (will only be used if enemies are used)
; * orientation - "up/down" "left/right" determines what direction the player is facing
; * lokey - list of keys in use
(define-struct Player [pos lives orn lokey])

; Key structure
; * id - a color matching the door it belongs to: red, yellow, green, blue
; * x and y - position of the key
; * have? - does the player have the key
(define-struct Key [id x y have?])

; Door structure: all information related to the doors
; * id - a color matching the key it belongs to: red, yellow, green, blue
; * pos - location of the door "right", "left", "top", or "bottom"
; * locked? - true if the door is still locked
; * open? - true if the door is open
(define-struct Door [id pos locked? open?])

; Enemy structure: all information related to the enemies (may not be used)
; * location - a posn with the (x y) location of the enemy
; * lives - remaining lives of the enemy (probably will not be used)
; if lives are not used this will just be a location pons in the WS structure
;(define-struct Enemy [location lives])

; Wall Structure (these are rectangles)
; x and y - the location of the wall
; width - width of image
; height - size of the image
; phase - solid or outline
; color - color of the image
(define-struct Wall [x y width height phase color])
; a full horizontal wall - x y 690 10 solid black
; a full vertical wall -   x y 10 690 solid black
; 3/7 horizontal wall -    x y 296 10 solid black
; 3/7 vertical wall -      x y 10 296 solid black

;Globals
(define BACKGROUND (square 700 'solid 'lightgrey))
(define PLAYERTOKEN (overlay (circle 25 'solid 'saddlebrown) (overlay (beside (circle 20 'solid 'slategrey) (circle 20 'solid 'slategrey)) (rectangle 100 50 'solid 'transparent))))
(define SPEED 10)
(define BRICK (overlay (rectangle 95 45 'outline 'black) (rectangle 100 50 'solid 'lightgrey)))
(define HORIZONTAL-DOOR (rectangle 98 10 'solid 'brown))
(define VERTICAL-DOOR (rectangle 10 98 'solid 'brown))
(define VERTICAL-KNOB (rectangle 5 10 'solid 'yellow))
(define HORIZONTAL-KNOB (rectangle 10 5 'solid 'yellow))
(define KEY (scale 2 (place-image (rectangle 3 2 'solid 'gold) 14 17
                                  (place-image (rectangle 3 2 'solid 'gold) 14 20
                                               (overlay (above (circle 5 'solid 'gold)
                                                               (rectangle 5 10 'solid 'gold))
                                                        (rectangle 20 25 'solid 'transparent))))))
  

; Worldstate -> Image
; Uses the worldstate to draw an image on screen
(define (render ws)
  (place-image
   (draw-player (WS-player ws))
   (posn-x (Player-pos (WS-player ws)))
   (posn-y (Player-pos (WS-player ws)))
   (draw-keys (WS-keys ws)
              (draw-doors (WS-lod ws)
                          (draw-walls (WS-low ws)
                                      (place-bricks BACKGROUND (/ (image-width BRICK) 2) (/ (image-height BRICK) 2)))))))

; Player structure -> image
; draws the playing in the proper orientation
(define (draw-player player)
  (cond [(string=? (Player-orn player) "up/down") PLAYERTOKEN]
        [(string=? (Player-orn player) "left/right") (rotate 90 PLAYERTOKEN)]))

; image, number, number, number -> image
; recursively places bricks on a background
(define (place-bricks img x y)
  (local [(define move-x (image-width BRICK))
          (define move-y (image-height BRICK))]
    (cond [(> y (image-height img)) img]
          [(> x (image-width img)) (place-bricks img (/ (image-width BRICK) 2) (+ y move-y))]
          [else (place-bricks (place-image BRICK x y img) (+ x move-x) y)])))

; list of walls, image -> image
; draws the list of walls on the background image
(define (draw-walls low img)
  (foldr draw-one-wall img low))

; wall structure, image -> image
; draws one Wall on the image
; (define-struct Wall (x y width height phase color))
(define (draw-one-wall wall img)
  (place-image (rectangle (Wall-width wall)
                          (Wall-height wall)
                          (Wall-phase wall)
                          (Wall-color wall))
               (Wall-x wall)
               (Wall-y wall)
               img))

; list of doors, image -> image
(define (draw-doors lod img)
  (foldr draw-one-door img lod))

; door structure, image -> image
; draws a door on the image
; [pos locked? open?]
(define (draw-one-door door img)
  (local [(define (top? d) (string=? "top" (Door-pos door)))
          (define (left? d) (string=? "left" (Door-pos door)))
          (define (bottom? d) (string=? "bottom" (Door-pos door)))
          (define (right? d) (string=? "right" (Door-pos door)))
          (define pos (Door-pos door))]
    (cond [(and (top? pos) (not (Door-open? door))) ; closed door on top wall
           (place-image HORIZONTAL-KNOB 380 18 (place-image HORIZONTAL-DOOR 350 10 img))]
          [(and (top? pos) (Door-open? door)) ; open door on top wall
           (place-image VERTICAL-KNOB 298 84 (place-image VERTICAL-DOOR 306 54 img))]
          [(and (right? pos) (not (Door-open? door))) ; closed door on left wall
           (place-image VERTICAL-KNOB 682 380 (place-image VERTICAL-DOOR 690 350 img))]
          [(and (right? pos) (Door-open? door)) ; open door on left wall
           (place-image HORIZONTAL-KNOB 616 298 (place-image HORIZONTAL-DOOR 646 306 img))]
          [(and (left? pos) (not (Door-open? door))) ; closed door on right wall
           (place-image VERTICAL-KNOB 18 320 (place-image VERTICAL-DOOR 10 350 img))]
          [(and (left? pos) (Door-open? door)) ; open door on right wall
           (place-image HORIZONTAL-KNOB 84 402 (place-image HORIZONTAL-DOOR 54 394 img))]
          [(and (bottom? pos) (not (Door-open? door))) ; closed door on bottom wall
           (place-image HORIZONTAL-KNOB 380 682 (place-image HORIZONTAL-DOOR 350 690 img))]
          [(and (bottom? pos) (Door-open? door)) ; open door on bottom wall
           (place-image VERTICAL-KNOB 402 616 (place-image VERTICAL-DOOR 394 646 img))])))

; list of Keys, image -> image
; Draw all the keys
(define (draw-keys keys img)
  (foldr draw-one-key img keys))

; Key, image -> img
; Draw one Key
(define (draw-one-key key img)
  (if (Key-have? key) img (place-image KEY (Key-x key) (Key-y key) img)))


; Worldstate -> Worldstate
; updates the worldstate on each tock
(define (tock ws)
  (local [(define filename (string-append "castlecrawlLevel" (number->string (WS-level ws)) ".txt"))
          (define newlow (walls-from-file filename))
          (define newlod (doors-from-file filename))
          (define newkeys (keys-from-file filename))
          (define newplayer (move-player (WS-player ws)))]
    (make-WS newplayer newkeys newlod newlow (WS-level ws) (WS-points ws))))

; filename -> list of walls
; creates a list of wall strucuters from the provided file
(define (walls-from-file filename)
  (local [(define lows (filter (lambda (li) (string=? (first li) "wall")) (read-words/line filename)))]
    (map los->wall lows)))

; list of strings -> list of walls
; turns a list of strings into a list of walls
; "x" "y" "690" "10" "solid" "black" -> [x y width height phase color]
(define (los->wall los)
  (make-Wall (string->number (second los)) (string->number (third los))
                 (string->number (fourth los)) (string->number (fifth los))
                 (sixth los) (seventh los)))

; filename -> list of doors
(define (doors-from-file filename)
  (local [(define lods (filter (lambda (li) (string=? (first li) "door")) (read-words/line filename)))]
    (map lod->door lods)))

; list of strings -> list of doors
; turns a list of strings into a list of doors
; door blue top #true #false -> [id pos locked? open?]
(define (lod->door los)
  (make-Door (second los) (third los) (string->boolean (fourth los)) (string->boolean (fifth los))))

;filename -> list of Keys
(define (keys-from-file filename)
  (local [(define keys (filter (lambda (li) (string=? (first li) "key")) (read-words/line filename)))]
    (map keys->Key keys)))

;list of strings -> Key
; turns a list of strings into a list of keys
; key blue 20 20 #true -> Key [id x y have?]
(define (keys->Key los)
  (make-Key (second los) (string->number (third los)) (string->number (fourth los)) (string->boolean (fifth los))))

; string -> boolean
; turns a string "true" or "false" into #true or #false
(define (string->boolean string)
  (string=? string "true"))

; Player Structure -> Player Stucture
; Moves the player
; prevents player from walking through walls (this doesn't work if I change the speed from 5)
(define (move-player player)
  (foldr move-player-helper player (Player-lokey player)))

(define (move-player-helper key player)
  (local [(define x (posn-x (Player-pos player)))
          (define y (posn-y (Player-pos player)))
          (define (update-player posn player lokey orn) (make-Player posn (Player-lives player) orn lokey))]
    (cond [(<= x 35) (update-player (make-posn (+ x SPEED) y) player empty (Player-orn player))]
          [(>= x 665) (update-player (make-posn (- x SPEED) y) player empty (Player-orn player))]
          [(<= y 35) (update-player (make-posn x (+ y SPEED)) player empty (Player-orn player))]
          [(>= y 665) (update-player (make-posn x (- y SPEED)) player empty (Player-orn player))]
          [(string=? "w" key) (update-player (make-posn x (- y SPEED)) player (Player-lokey player) "up/down")]
          [(string=? "a" key) (update-player (make-posn (- x SPEED) y) player (Player-lokey player) "left/right")]
          [(string=? "s" key) (update-player (make-posn x (+ y SPEED)) player (Player-lokey player) "up/down")]
          [(string=? "d" key) (update-player (make-posn (+ x SPEED) y) player (Player-lokey player) "left/right")])))

; Worldstate, key -> Worldstate
; updates the worldstate when a key is pressed
(define (key-handler ws key)
  (make-WS (handle-movement (WS-player ws) key)
           (take-key (WS-player ws) (WS-keys ws) key)
           (open-door ws (WS-lod ws) key)
           (WS-low ws)
           (WS-level ws)
           (WS-points ws)))

; Player structure, Key -> Worldstate
; updates the current list of keys (lokey) in the Player structure
(define (handle-movement player key)
  (if (or (string=? key "w") (string=? key "a")
          (string=? key "s") (string=? key "d"))
      (make-Player (Player-pos player)
                   (Player-lives player)
                   (Player-orn player)
                   (cons key (remove key (Player-lokey player))))
      player))

; Player, list of keys, key -> list of keys
; takes the key if the player is near it
;[id x y have?]
(define (take-key player keys key)
  (if (string=? "e" key)
      (map (lambda (key1) (if (and (<= (- (Key-x key1) 50) (posn-x (Player-pos player)) (+ (Key-x key1) 50))
                                   (<= (- (Key-y key1) 50) (posn-y (Player-pos player)) (+ (Key-y key1) 50)))
                              (make-Key (Key-id key1)
                                        (Key-x key1)
                                        (Key-y key1)
                                        #true)
                              key1)) keys)
      keys))

; worldstate, key -> list of Doors
;[id pos locked? open?]
(define (open-door ws lod key)
  (local [(define keys (WS-keys ws))
          (define player (WS-player ws))]
    (if (string=? key "e")
        (cond [(empty? keys) lod]
              [(empty? lod) lod]
              [(and (key-for-door keys (first lod))
                    (string=? (Door-pos (first lod)) (player-pos player)))
               (cons (make-Door (Door-id (first lod))
                                (Door-pos (first lod))
                                #false
                                #true)
                     (open-door ws (rest lod) key))]
              [else (cons (first lod) (open-door ws (rest lod) key))])
        lod)))
#|(check-expect (open-door (make-WS
                          (make-Player (make-posn 610 350) 10 "left/right" '())
                          (list (make-Key "blue" 50 650 #true))
                          (list (make-Door "blue" "left" #true #false))
                          (list
                           (make-Wall 350 10 680 10 "solid" "black")
                           (make-Wall 350 690 690 10 "solid" "black")
                           (make-Wall 10 350 10 690 "solid" "black")
                           (make-Wall 690 153 10 296 "solid" "black")
                           (make-Wall 690 542 10 296 "solid" "black"))
                          1
                          0)
                         (list (make-Door "blue" "left" #true #false))
                         "\r")
              (list (make-Door "blue" "left" #true #true)))|#

; Player -> string
; produces a string--top, bottom, left, right--determind by they player's x and y
(define (player-pos player)
            (cond [(and (>= (posn-x (Player-pos player)) 600)
                        (<= 300 (posn-y (Player-pos player)) 400))
                   "right"]
                  [(and (>= (posn-x (Player-pos player)) 100)
                        (<= 300 (posn-y (Player-pos player)) 400))
                   "left"]
                  [(and (<= 300 (posn-x (Player-pos player)) 400)
                        (<= (posn-y (Player-pos player)) 100))
                   "top"]
                  [(and (<= 300 (posn-x (Player-pos player)) 400)
                        (>= (posn-y (Player-pos player)) 600))
                   "bottom"]
                  [else "center"]))
;(check-expect (player-pos (make-Player (make-posn 640 350) 10 "left/right" empty)) "right") 

; list of Keys, door -> Key
(define (key-for-door keys door)
  (not (empty? (filter (lambda (key)
            (and (string=? (Key-id key) (Door-id door))
                 (Key-have? key)))
          keys))))
;(check-expect (key-for-door (list (make-Key "blue" 20 30 #true) (make-Key "yellow" 40 50 #false)) (make-Door "blue" "top" #true #false)) (make-Key "blue" 20 30 #true))

; Worldstate, key -> Worldstate
; removes the released key from Player-lokey
; [pos lives orn lokey]
(define (key-release-handler ws key)
  (local [(define (remove-key key player) (make-Player (Player-pos player)
                                                       (Player-lives player)
                                                       (Player-orn player)
                                                       (remove key (Player-lokey player))))]
    (make-WS (remove-key key (WS-player ws))
             (WS-keys ws)
             (WS-lod ws)
             (WS-low ws)
             (WS-level ws)
             (WS-points ws))))


; Worldstate, mouse x, mouse y, mouse event -> Worldstate
; updates the worldstate when the mouse is used
(define (mouse-handler ws x y evt) ws)

;[player keys lod low level points]
(define initial-ws (make-WS (make-Player (make-posn 350 350) 10 "up/down" empty) empty empty empty 1 0))

(big-bang initial-ws
  (on-draw render)
  (on-tick tock)
  (on-key key-handler)
  (on-release key-release-handler)
  (on-mouse mouse-handler))
  