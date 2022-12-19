;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname |Final Project - V10 - final edits|) (read-case-sensitive #t) (teachpacks ((lib "image.rkt" "teachpack" "2htdp") (lib "universe.rkt" "teachpack" "2htdp"))) (htdp-settings #(#t constructor repeating-decimal #t #t none #f ((lib "image.rkt" "teachpack" "2htdp") (lib "universe.rkt" "teachpack" "2htdp")) #f)))
(require racket/list)
(require 2htdp/batch-io)
(require 2htdp/image)
(require racket/struct)

; Exposition Worldstate
; * page - a number representing the page of text the player is on
; * string - the text that will be displayed on screen
; * t - a number representing when the page will close. Only effects the last page
; * ing - a string representing the ingredient for that level | #false if no ingredient is to be displayed
(define-struct ExpoWS [page string t ing])

; Worldstate structure
; * player - a structure containing information directly related to the player character
; * room - current room structure
; * levelkeys - a list of all the keys for that level and if the player has them
; * have-ing? - a boolean have the potion ingredient for that level
; * display-keys? - a boolean should the keys be displayed
(define-struct WS [player room levelkeys have-ing? display-keys?])

; Player structure: all fields directly related to the player character
; * pos - a posn with the (x y) location of the player
; * orn - orientation a string "up/down" "left/right" determines what direction the player is facing
; * lokey - list of keys in use
(define-struct Player [pos orn lokey])

; Room structure
; * rid - room id number - eg. 1.1 level 1 room 1
; * keys - list of key structures
; * lod - a list where each member is a Door structure
; * low - a list of walls for the current level
; * ing - a structure for the ingredient
; * items - a list of the items in the room
(define-struct Room [rid keys lod low ing items])

; Key structure
; * id - a string "A", "B", "C", or "D", etc matching the id of the door
; * x and y - position of the key
(define-struct Key [id x y])
; key "A" 200 350 false

; Door structure: all information related to the doors
; * id - a string "A", "B", "C", or "D", etc matching the id of the key
; * pos - a string that is the location of the door "right", "left", "top", or "bottom"
; * locked? - a boolean true if the door is still locked
; * open? - a boolean true if the door is open
; * nxt# - next room or page | a number representing the room or page this door leads to
; * nxttype - a string "page" or "room"
(define-struct Door [id pos locked? open? nxt# nxttype])
; door "A" bottom true false 2.1 page

; Wall Structure (these are rectangles)
; x and y - numbers - the location of the wall
; width - number - width of image
; height - number - size of the image
(define-struct Wall [x y width height])
; wall 350 10 690 10 - top full horizontal wall
; wall 350 690 690 10 - bottom full horizontal wall
; wall 10 350 10 690 - left full vertical wall
; wall 690 350 10 690 - right full vertical wall
; wall 153 10 296 10 - top 3/7 horizontal wall
; wall 542 10 296 10 - top 3/7 horizontal wall
; wall 153 690 296 10 - bottom 3/7 horizontal wall
; wall 542 690 296 10 - bottom 3/7 horizontal wall
; wall 690 153 10 296 - right 3/7 vertical wall
; wall 690 542 10 296 - right 3/7 vertical wall
; wall 10 153 10 296 - left 3/7 vertical wall
; wall 10 542 10 296 - left 3/7 vertical wall

; Ing Structure
; type - string - which ingredient is it 
; x and y - numbers - the location of the ingredient
(define-struct Ing [type x y])

; Item Structure
; type - string -vwhich item is it
; x and y - numbers - the location of the item
(define-struct Item [type x y])

; Levelkeys structure
; * id - a letter A, B, C, D, etc matching the id of the door (and the actual key)
; * have? - boolean - does the player have the key
(define-struct Levelkey [id have?])

; Trollstate
; * t - a number counting down
(define-struct Trollstate [t])

(define level1keys (list (make-Levelkey "A" #false)
                         (make-Levelkey "B" #false)))

(define level2keys (list (make-Levelkey "A" #false)
                         (make-Levelkey "B" #false)
                         (make-Levelkey "C" #false)
                         (make-Levelkey "D" #false)))

(define level3keys (list (make-Levelkey "A" #false)
                         (make-Levelkey "B" #false)
                         (make-Levelkey "C" #false)
                         (make-Levelkey "D" #false)
                         (make-Levelkey "E" #false)
                         (make-Levelkey "F" #false)))

;Globals
(define BACKGROUND (square 700 'solid 'lightgrey))
(define EXPO-BACKGROUND (square 700 'solid 'lightblue))
(define PLAYERTOKEN (overlay (circle 25 'solid 'saddlebrown) (overlay (beside (circle 20 'solid 'slategrey) (circle 20 'solid 'slategrey)) (rectangle 100 50 'solid 'transparent))))
(define SPEED 10)
(define BRICK (overlay (rectangle 95 45 'outline 'black) (rectangle 100 50 'solid 'lightgrey)))
(define HORIZONTAL-DOOR (overlay (rectangle 92 6 'solid 'lightbrown) (rectangle 98 10 'solid 'white)))
(define VERTICAL-DOOR (overlay (rectangle 6 92 'solid 'lightbrown) (rectangle 10 98 'solid 'white)))
; Doorknobs
(define VERTICAL-KNOB-A (rectangle 5 10 'solid 'white))
(define HORIZONTAL-KNOB-A (rectangle 10 5 'solid 'white))
(define VERTICAL-KNOB-B (rectangle 5 10 'solid 'red))
(define HORIZONTAL-KNOB-B (rectangle 10 5 'solid 'red))
(define VERTICAL-KNOB-C (rectangle 5 10 'solid 'orange))
(define HORIZONTAL-KNOB-C (rectangle 10 5 'solid 'orange))
(define VERTICAL-KNOB-D (rectangle 5 10 'solid 'green))
(define HORIZONTAL-KNOB-D (rectangle 10 5 'solid 'green))
(define VERTICAL-KNOB-E (rectangle 5 10 'solid 'blue))
(define HORIZONTAL-KNOB-E (rectangle 10 5 'solid 'blue))
(define VERTICAL-KNOB-F (rectangle 5 10 'solid 'hotpink))
(define HORIZONTAL-KNOB-F (rectangle 10 5 'solid 'hotpink))

(define BASEKEY (scale 2 (place-image (rectangle 3 2 'solid 'gold) 14 17
                                  (place-image (rectangle 3 2 'solid 'gold) 14 20
                                               (overlay (above (circle 5 'solid 'gold)
                                                               (rectangle 5 10 'solid 'gold))
                                                        (rectangle 20 25 'solid 'transparent))))))
(define WHITEKEY (place-image (circle 5 'solid 'white) 20 15 BASEKEY))
(define REDKEY (place-image (circle 5 'solid 'red) 20 15 BASEKEY))
(define ORANGEKEY (place-image (circle 5 'solid 'orange) 20 15 BASEKEY))
(define GREENKEY (place-image (circle 5 'solid 'green) 20 15 BASEKEY))
(define BLUEKEY (place-image (circle 5 'solid 'blue) 20 15 BASEKEY))
(define HOTPINKKEY (place-image (circle 5 'solid 'hotpink) 20 15 BASEKEY))                                                           
(define BLUEAPPLE (place-image (rotate 45 (ellipse 10 2 'solid 'green))
                               20 2
                               (overlay (above (rectangle 5 2 'solid 'brown)
                                               (circle '10 'solid 'blue))
                                        (square 30 'solid 'transparent))))
(define ORANGEPOTION (scale 2 (place-image (above (rectangle 7 2 'solid 'tan)
                                         (rectangle 5 10 'solid 'orange))
                                  15 10
                                  (place-image (triangle 20 'solid 'orange)
                                               15 20 (square 30 'solid 'transparent)))))
(define POTATO (scale 2 (local [(define eye (circle 0.5 'solid 'white))]
                        (place-images (list eye eye eye eye eye eye)
                                      (list (make-posn 4 3)
                                            (make-posn 12 8)
                                            (make-posn 3 5)
                                            (make-posn 8 2)
                                            (make-posn 19 4)
                                            (make-posn 3 8))
                                      (ellipse 20 10 'solid 'tan)))))
(define SIDETABLE (circle 50 'solid 'brown))
(define DININGTABLE 
  (local [(define plate (overlay (circle 20 'solid 'white)
                                 (circle 25 'solid 'lightgrey)))]
    (place-images (list plate plate plate plate plate plate plate plate plate plate)
                  (list (make-posn 40 100)
                        (make-posn 100 40)
                        (make-posn 200 40)
                        (make-posn 300 40)
                        (make-posn 400 40)
                        (make-posn 460 100)
                        (make-posn 100 160)
                        (make-posn 200 160)
                        (make-posn 300 160)
                        (make-posn 400 160))
                  (rectangle 500 200 'solid 'saddlebrown))))
(define UPCHAIR (scale 1.5
                       (overlay (beside/align "bottom"
                                              (rectangle 7 50 'solid 'brown)
                                              (rectangle 36 7 'solid 'brown)
                                              (rectangle 7 50 'solid 'brown))
                                (circle 25 'solid 'darkbrown))))
(define LEFTCHAIR (rotate 90 UPCHAIR))
(define RIGHTCHAIR (rotate 270 UPCHAIR))
(define DOWNCHAIR (rotate 180 UPCHAIR))
(define BUFFETTABLE (rectangle 200 75 'solid 'brown))
(define PLANT (local [(define leaf1 (ellipse 25 15 'solid 'green))
                      (define leaf2 (ellipse 15 10 'solid 'lightgreen))
                      (define leaf3 (ellipse 40 20 'solid 'darkgreen))]
                (place-images (list leaf2 (rotate 60 leaf2) (rotate 25 leaf1) (rotate 160 leaf1) (rotate 0 leaf1)
                                    leaf3 (rotate 45 leaf3) (rotate 75 leaf3))
                              (list (make-posn 25 25)
                                    (make-posn 32 23)
                                    (make-posn 25 32)
                                    (make-posn 25 25)
                                    (make-posn 35 30)
                                    (make-posn 25 32)
                                    (make-posn 25 25)
                                    (make-posn 35 30))
                              (overlay (overlay (circle 25 'solid 'black)
                                                (circle 30 'solid 'red))
                                       (square 60 'solid 'transparent)))))
(define FOUNTAIN (overlay (rotate 135 (ellipse 20 50 'solid 'aliceblue))
                          (overlay (rotate 45 (ellipse 20 50 'solid 'aliceblue))
                                   (overlay (rotate 90 (ellipse 50 75 'solid 'lightblue))
                                            (overlay (ellipse 50 75 'solid 'lightblue)
                                                     (overlay (circle 90 'solid 'skyblue)
                                                              (circle 100 'solid 'darkgrey)))))))
(define BED (scale 0.75 (place-images (list
                           (above
                                 (overlay (rectangle 70 95 'solid 'Gainsboro) (rectangle 75 100 'solid 'transparent))
                                 (overlay (rectangle 70 95 'solid 'Gainsboro) (rectangle 75 100 'solid 'transparent)))
                           (scale 0.7 (bitmap/file "quilt.png"))) ; quilt image by pixel1 on pixabay
                          (list (make-posn 350 100)
                                (make-posn 150 100))
                          (overlay (rectangle 390 190 'solid 'Ivory)
                                   (rectangle 400 200 'solid 'saddlebrown)))))
(define SOFA (place-image (above (overlay (rectangle 65 70 'solid 'darkblue) (rectangle 70 75 'solid 'transparent))
                                 (overlay (rectangle 65 70 'solid 'darkblue) (rectangle 70 75 'solid 'transparent)))
                          70 100
                          (rectangle 100 200 'solid 'lightblue)))
(define BATHTUB (local [(define foot (circle 5 'solid 'gold))]
                  (overlay
                   (place-image (rectangle 10 20 'solid 'gold)
                                50 15
                                (overlay (ellipse 90 190 'solid 'gainsboro)
                                         (ellipse 100 200 'solid 'whitesmoke)))
                                (place-images (list foot foot foot foot)
                                              (list (make-posn 20 20)
                                                    (make-posn 80 20)
                                                    (make-posn 20 180)
                                                    (make-posn 80 180))
                                              (rectangle 100 200 'solid 'transparent)))))
(define TOILET (rotate -90
                       (overlay (place-images (list (rectangle 70 20 'solid 'whitesmoke)
                                                    (rectangle 10 5 'solid 'gold))
                                              (list (make-posn 35 10)
                                                    (make-posn 50 20))
                                              (circle 35 'solid 'gainsboro))
                                (rectangle 70 85 'solid 'transparent))))
(define SINK (place-image (rectangle 10 5 'solid 'gold)
                          40 (/ 75 2)
                          (overlay (ellipse 35 50 'solid 'gainsboro)
                                   (rectangle 50 75 'solid 'whitesmoke))))
; Wall from nikiko on pixabay
(define TROLLWALL (scale 0.57 (bitmap/file "wall-pixabay-nikiko-cropped.jpg")))
; Troll from anaterate on pixabay
(define TROLL (scale 1.5 (bitmap/file "troll-pixabay-anaterate.png")))
; Man from silvia on pixabay
(define MAN (scale 1.5 (scale 0.177 (bitmap/file "man-silvia-pixabaay.png"))))


; room identification number, filename -> Worldstate
; uses a file to update the worldstate to make a room
(define (make-a-room rid filename)
  (local [(define newlow (walls-from-file filename))
          (define newlod (doors-from-file filename))
          (define newkeys (keys-from-file filename))
          (define newing (ing-from-file filename))
          (define newitem (items-from-file filename))]
    (make-Room rid newkeys newlod newlow newing newitem)))

; filename -> list of walls
; creates a list of wall structures from the provided file
(define (walls-from-file filename)
  (local [(define lows (filter (lambda (li) (string=? (first li) "wall")) (read-words/line filename)))]
    (map los->wall lows)))

; list of strings -> list of walls
; turns a list of strings into a wall
; "x" "y" "690" "10" -> [x y width height]
(define (los->wall los)
  (make-Wall (string->number (second los)) (string->number (third los))
             (string->number (fourth los)) (string->number (fifth los))))

; filename -> list of doors
; turns a list of strings into a list of door structures
(define (doors-from-file filename)
  (local [(define lods (filter (lambda (li) (string=? (first li) "door")) (read-words/line filename)))]
    (map lod->door lods)))

; list of strings -> list of doors
; turns a list of strings into a a door structure
; door A top #true #false 1.2 room -> [id pos locked? open? nxt# nxttype]
(define (lod->door los)
  (make-Door (second los) (third los) (string->boolean (fourth los)) (string->boolean (fifth los)) (string->number (sixth los)) (seventh los)))

;filename -> list of Keys
; retrives the keys from the file
(define (keys-from-file filename)
  (local [(define keys (filter (lambda (li) (string=? (first li) "key")) (read-words/line filename)))]
    (map keys->Key keys)))

;list of strings -> Key
; turns a list of strings into a key structure
; key blue 20 20 -> Key [id x y]
(define (keys->Key los)
  (make-Key (second los) (string->number (third los)) (string->number (fourth los))))

; filename -> Ing
; turns a list of strings into an ingredient
; there will only be one ingredient per level
(define (ing-from-file filename)
  [local [(define ing (foldr (lambda (li acc) (if (string=? (first li) "ing") li acc)) empty (read-words/line filename)))]
    (if (not (empty? ing))
        (make-Ing (cond [(string=? (second ing) "blueapple") BLUEAPPLE]
                                           [(string=? (second ing) "orangepotion") ORANGEPOTION]
                                           [(string=? (second ing) "potato") POTATO])
                                     (string->number (third ing))
                                     (string->number (fourth ing)))
        empty)])

; filename -> list of items
; retrives the items from the file
(define (items-from-file filename)
  (local [(define items (filter (lambda (li) (string=? (first li) "item")) (read-words/line filename)))]
    (map items->Item items)))

; list of strings -> Item
; turns a list of strings into an Item structure
; item diningtable 350 350 -> Item [type x y]
(define (items->Item los)
  (make-Item (second los) (string->number (third los)) (string->number (fourth los))))

; string -> boolean
; turns a string "true" or "false" into #true or #false
(define (string->boolean string)
  (string=? string "true"))

;ExpoWS [string page]
(define page1.1 (make-ExpoWS 1.1 "Welcome to Castle Crawl!\n\nTo play use WASD to move around\nUse E to pick up keys or ingredients and open doors\nHold down Q to view the keys you have collected\n\nEach level you will need to collect all the keys\nand the ingredient in order to move on.\n\nThe ingredient will be displayed on the page it is mentioned.\nThe keys are color coded to the doorknobs.\n\nPress enter to continue from this screen" 0 #false))
(define page1.2 (make-ExpoWS 1.2 "Madam Marvelous:\n\nBack again young one?\nHaven't you had enough of pastules and potions.\n\nI heard about the troll incident in your home,\nbut I've noticed that young Joffrey\nstill roams around the town.\nThat means the the troll transformation potion\nwasn't used on him.\nWho is the troll then?\n\nPress enter" 0 #false))
(define page1.3 (make-ExpoWS 1.3 "Player:\n\nIt's... It's my father\nHe found the potion before I could give it to Joffrey.\nSomehow he knew what it was.\nWe started fighting over it and\nI tried to grab it from him, but he jerked his hand back\nand it fell. It smashed at his bare feet and,\nnext thing I knew,\nhe was a troll.\n\nPress enter" 0 #false))
(define page1.4 (make-ExpoWS 1.4 "Madam Marvelous:\n\nHere is what you are going to do:\n\nYou need to gather some ingredients\nfrom around my house so I can turn him back.\nStart with the blue apple on the first floor...\n\nPress enter" 0 "blueapple"))
(define page1.5 (make-ExpoWS 1.5 "Ready?\n\nPress enter" 0 #false))
(define page2.1 (make-ExpoWS 2.1 "Madam Marvelous:\n\nThen you will need the orange potion from the second floor...\n\nPress enter" 0 "orangepotion"))
(define page2.2 (make-ExpoWS 2.2 "Ready?\n\nPress enter" 0 #false))
(define page3.1 (make-ExpoWS 3.1 "Madam Marvelous:\n\nFinally you must retrieve the potato on the third floor...\n\nPress enter" 0 #false))
(define page4.1 (make-ExpoWS 4.1 "Madam Marvelous:\n\nNow then. I see you have found everything I need for my lunch.\n\nAnyhoo, take this lemon.\n\nTrolls don't like them much, so it will be hard to get\nhim to eat it,\nbut it will turn anything that is not a troll\nback into its true form\n\nPress enter" 0 #false))
(define page4.2 (make-ExpoWS 4.2 "Father:\n\nWhat have you done!\nI hope from now one you have a VERY INTERESTING life\n\nPress enter" 0 #false))
(define page4.3 (make-ExpoWS 4.3 "Great job!\n\nYou saved your father\n\nHe dragged you off by your ear\nand put you to work slopping out the stables\nbut you're just relieved he is okay.\n\n\nEST FINEM" 100 #false))

(define pages (list page1.1 page1.2 page1.3 page1.4 page1.5
                    page2.1 page2.2
                    page3.1
                    page4.1 page4.2 page4.3))

(define room1.1 (make-a-room 1.1 "castleCrawlLevel1.1.txt"))
(define room1.2 (make-a-room 1.2 "castleCrawlLevel1.2.txt"))
(define room2.1 (make-a-room 2.1 "castleCrawlLevel2.1.txt"))
(define room2.2 (make-a-room 2.2 "castleCrawlLevel2.2.txt"))
(define room2.3 (make-a-room 2.3 "castleCrawlLevel2.3.txt"))
(define room2.4 (make-a-room 2.4 "castleCrawlLevel2.4.txt"))
(define room3.1 (make-a-room 3.1 "castleCrawlLevel3.1.txt"))
(define room3.2 (make-a-room 3.2 "castleCrawlLevel3.2.txt"))
(define room3.3 (make-a-room 3.3 "castleCrawlLevel3.3.txt"))
(define room3.4 (make-a-room 3.4 "castleCrawlLevel3.4.txt"))
(define room3.5 (make-a-room 3.5 "castleCrawlLevel3.5.txt"))
(define room3.6 (make-a-room 3.6 "castleCrawlLevel3.6.txt"))

(define rooms (list room1.1 room1.2
                    room2.1 room2.2 room2.3 room2.4
                    room3.1 room3.2 room3.3 room3.4 room3.5 room3.6))

; --------------------------------------------------

; Worldstate -> Image
; Draws an image on screen according to which worldstate structure is in use
(define (render ws)
  (cond [(WS? ws) (render-WS ws)]
        [(ExpoWS? ws) (render-ExpoWS ws)]
        [else (render-Trollstate ws)]))

; Worldstate -> Image
; Uses the ExpoWS worldstate to draw an image on screen
(define (render-ExpoWS ws)
  (local [(define ingredient (cond [(boolean? (ExpoWS-ing ws)) empty-image]
                                   [(string=? "blueapple" (ExpoWS-ing ws)) (scale 2 BLUEAPPLE)]
                                   [(string=? "orangepotion" (ExpoWS-ing ws)) ORANGEPOTION]
                                   [(string=? "potato" (ExpoWS-ing ws)) POTATO]))]
    (overlay (above (text (ExpoWS-string ws) 24 'black) ingredient) EXPO-BACKGROUND)))

; Worldstate -> Image
; Uses the WS worldstate to draw an image on screen
(define (render-WS ws)
  (overlay/align "middle" "top" (display-keys ws)
           (place-image
            (draw-player (WS-player ws))
            (posn-x (Player-pos (WS-player ws)))
            (posn-y (Player-pos (WS-player ws)))
            (draw-ing ws (Room-ing (WS-room ws))
                      (draw-keys (WS-levelkeys ws) (Room-keys (WS-room ws))
                                 (draw-items (Room-items (WS-room ws))
                                             (draw-doors (Room-lod (WS-room ws))
                                                         (draw-walls (Room-low (WS-room ws))
                                                                     (place-bricks BACKGROUND (/ (image-width BRICK) 2) (/ (image-height BRICK) 2))))))))))

; Worldstate -> Image
; displays the keys the player has collected
(define (display-keys ws)
  (if (WS-display-keys? ws)
      (local [(define collected-keys (filter (lambda (li) (Levelkey-have? li)) (WS-levelkeys ws)))
              (define key-background (overlay/align "left" "top" (text "You have these keys:" 25 'white) (rectangle 700 100 'solid 'black)))]
        (draw-keys-on-background collected-keys 100 key-background))
      empty-image))

; list of Levelkey, number, image -> image
; draws the Levelkeys on the collected keys screen
(define (draw-keys-on-background levelkeys x img)
      (cond [(empty? levelkeys) img]
            [(string=? (Levelkey-id (first levelkeys)) "A")
             (draw-keys-on-background (rest levelkeys) (+ 50 x) (place-image WHITEKEY x 50 img))]
            [(string=? (Levelkey-id (first levelkeys)) "B")
             (draw-keys-on-background (rest levelkeys) (+ 50 x) (place-image REDKEY x 50 img))]
            [(string=? (Levelkey-id (first levelkeys)) "C")
             (draw-keys-on-background (rest levelkeys) (+ 50 x) (place-image ORANGEKEY x 50 img))]
            [(string=? (Levelkey-id (first levelkeys)) "D")
             (draw-keys-on-background (rest levelkeys) (+ 50 x) (place-image GREENKEY x 50 img))]
            [(string=? (Levelkey-id (first levelkeys)) "E")
             (draw-keys-on-background (rest levelkeys) (+ 50 x) (place-image BLUEKEY x 50 img))]
            [(string=? (Levelkey-id (first levelkeys)) "F")
             (draw-keys-on-background (rest levelkeys) (+ 50 x) (place-image HOTPINKKEY x 50 img))]))


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
; (define-struct Wall (x y width height))
(define (draw-one-wall wall img)
  (place-image (rectangle (Wall-width wall)
                          (Wall-height wall)
                          'solid
                          'black)
               (Wall-x wall)
               (Wall-y wall)
               img))

; list of doors, image -> image
; draw all the doors on the image
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
          (define pos (Door-pos door))
          (define horizontal-knob (cond [(string=? (Door-id door) "A") HORIZONTAL-KNOB-A]
                                        [(string=? (Door-id door) "B") HORIZONTAL-KNOB-B]
                                        [(string=? (Door-id door) "C") HORIZONTAL-KNOB-C]
                                        [(string=? (Door-id door) "D") HORIZONTAL-KNOB-D]
                                        [(string=? (Door-id door) "E") HORIZONTAL-KNOB-E]
                                        [(string=? (Door-id door) "F") HORIZONTAL-KNOB-F]))
          (define vertical-knob (cond [(string=? (Door-id door) "A") VERTICAL-KNOB-A]
                                      [(string=? (Door-id door) "B") VERTICAL-KNOB-B]
                                      [(string=? (Door-id door) "C") VERTICAL-KNOB-C]
                                      [(string=? (Door-id door) "D") VERTICAL-KNOB-D]
                                      [(string=? (Door-id door) "E") VERTICAL-KNOB-E]
                                      [(string=? (Door-id door) "F") VERTICAL-KNOB-F]))]
    (cond [(and (top? pos) (not (Door-open? door))) ; closed door on top wall
           (place-image horizontal-knob 380 18 (place-image HORIZONTAL-DOOR 350 10 img))]
          [(and (top? pos) (Door-open? door)) ; open door on top wall
           (place-image vertical-knob 298 84 (place-image VERTICAL-DOOR 306 54 img))]
          [(and (right? pos) (not (Door-open? door))) ; closed door on left wall
           (place-image vertical-knob 682 380 (place-image VERTICAL-DOOR 690 350 img))]
          [(and (right? pos) (Door-open? door)) ; open door on left wall
           (place-image horizontal-knob 616 298 (place-image HORIZONTAL-DOOR 646 306 img))]
          [(and (left? pos) (not (Door-open? door))) ; closed door on right wall
           (place-image vertical-knob 18 320 (place-image VERTICAL-DOOR 10 350 img))]
          [(and (left? pos) (Door-open? door)) ; open door on right wall
           (place-image horizontal-knob 84 402 (place-image HORIZONTAL-DOOR 54 394 img))]
          [(and (bottom? pos) (not (Door-open? door))) ; closed door on bottom wall
           (place-image horizontal-knob 380 682 (place-image HORIZONTAL-DOOR 350 690 img))]
          [(and (bottom? pos) (Door-open? door)) ; open door on bottom wall
           (place-image vertical-knob 402 616 (place-image VERTICAL-DOOR 394 646 img))])))

; list of Levelkeys, list of Keys, image -> image
; Draw all the keys
(define (draw-keys levelkeys keys img)
  (cond [(empty? levelkeys) img]
        [else (local [(define keymatch (keyvkey (first levelkeys) keys))
                      (define keyimage (cond [(string=? (Levelkey-id (first levelkeys)) "A") WHITEKEY]
                                          [(string=? (Levelkey-id (first levelkeys)) "B") REDKEY]
                                          [(string=? (Levelkey-id (first levelkeys)) "C") ORANGEKEY]
                                          [(string=? (Levelkey-id (first levelkeys)) "D") GREENKEY]
                                          [(string=? (Levelkey-id (first levelkeys)) "E") BLUEKEY]
                                          [(string=? (Levelkey-id (first levelkeys)) "F") HOTPINKKEY]
                                          ))]
                (cond [(boolean? keymatch) (draw-keys (rest levelkeys) keys img)]
                      [(not (Levelkey-have? (first levelkeys))) (draw-keys (rest levelkeys)
                                                                           keys
                                                                           (place-image
                                                                            keyimage
                                                                            (Key-x keymatch)
                                                                            (Key-y keymatch)
                                                                            img))]
                      [else (draw-keys (rest levelkeys) keys img)]))]))

; Worldstate, Ing structure, ing -> image
; draws the ingredients on screen
(define (draw-ing ws ing img)
  (if (and (Ing? ing) (not (WS-have-ing? ws))) (place-image (Ing-type ing) (Ing-x ing) (Ing-y ing) img) img))

; Levelkey, list of Keys -> Key or #false
; compares the keys in the room to the a levelkey
; to determine if that key is in the room
; returns the key if it is
; returns false if it is not
(define (keyvkey levelkey keys)
  (foldr (lambda (key acc) (if (string=? (Levelkey-id levelkey) (Key-id key)) key acc)) #false keys))

; List of Items, image -> image
; draws the items on the page
(define (draw-items loi img)
  (cond [(empty? loi) img]
        [(string=? (Item-type (first loi)) "plant") (draw-items (rest loi) (place-image PLANT (Item-x (first loi)) (Item-y (first loi)) img))]
        [(string=? (Item-type (first loi)) "sidetable") (draw-items (rest loi) (place-image SIDETABLE (Item-x (first loi)) (Item-y (first loi)) img))]
        [(string=? (Item-type (first loi)) "diningtable") (draw-items (rest loi) (place-image DININGTABLE (Item-x (first loi)) (Item-y (first loi)) img))]
        [(string=? (Item-type (first loi)) "buffettable") (draw-items (rest loi) (place-image BUFFETTABLE (Item-x (first loi)) (Item-y (first loi)) img))]
        [(string=? (Item-type (first loi)) "fountain") (draw-items (rest loi) (place-image FOUNTAIN (Item-x (first loi)) (Item-y (first loi)) img))]
        [(string=? (Item-type (first loi)) "bed") (draw-items (rest loi) (place-image BED (Item-x (first loi)) (Item-y (first loi)) img))]
        [(string=? (Item-type (first loi)) "sofa") (draw-items (rest loi) (place-image SOFA (Item-x (first loi)) (Item-y (first loi)) img))]
        [(string=? (Item-type (first loi)) "upchair") (draw-items (rest loi) (place-image UPCHAIR (Item-x (first loi)) (Item-y (first loi)) img))]
        [(string=? (Item-type (first loi)) "downchair") (draw-items (rest loi) (place-image DOWNCHAIR (Item-x (first loi)) (Item-y (first loi)) img))]
        [(string=? (Item-type (first loi)) "leftchair") (draw-items (rest loi) (place-image LEFTCHAIR (Item-x (first loi)) (Item-y (first loi)) img))]
        [(string=? (Item-type (first loi)) "rightchair") (draw-items (rest loi) (place-image RIGHTCHAIR (Item-x (first loi)) (Item-y (first loi)) img))]
        [(string=? (Item-type (first loi)) "sink") (draw-items (rest loi) (place-image SINK (Item-x (first loi)) (Item-y (first loi)) img))]
        [(string=? (Item-type (first loi)) "toilet") (draw-items (rest loi) (place-image TOILET (Item-x (first loi)) (Item-y (first loi)) img))]
        [(string=? (Item-type (first loi)) "bathtub") (draw-items (rest loi) (place-image BATHTUB (Item-x (first loi)) (Item-y (first loi)) img))]
        [else (draw-items (rest loi) img)]))

; Worldstate -> image
; draws the troll level
(define (render-Trollstate ws)
  (cond [(>= 0 (Trollstate-t ws)) (place-image MAN 200 460 TROLLWALL)]
        [(>= 20 (Trollstate-t ws)) (place-image (scale 1.2 TROLL) 200 460 TROLLWALL)]
        [(>= 40 (Trollstate-t ws)) (place-image (scale 1.4 TROLL) 200 460 TROLLWALL)]
        [(>= 60 (Trollstate-t ws)) (place-image (scale 1.6 TROLL) 200 460 TROLLWALL)]
        [(>= 80 (Trollstate-t ws)) (place-image (scale 1.8 TROLL) 200 460 TROLLWALL)]
        [else (place-image (scale 2 TROLL) 200 460 TROLLWALL)]))

; Worldstate -> Worldstate
; updates the worldstate on each tock
(define (tock ws)
  (cond [(WS? ws)
         (local [(define newplayer (move-player (WS-player ws) (WS-room ws) (Player-lokey (WS-player ws))))
                 (define newroom (change-room ws))]
           (if (not (boolean? newroom)) newroom (make-WS newplayer (WS-room ws) (WS-levelkeys ws) (WS-have-ing? ws) (WS-display-keys? ws))))]
        [(Trollstate? ws) (if (> (Trollstate-t ws) -100) (make-Trollstate (- (Trollstate-t ws) 1)) page4.2)]
        [(and (ExpoWS? ws) (= (ExpoWS-page ws) 4.3)) (make-ExpoWS (ExpoWS-page ws) (ExpoWS-string ws) (- (ExpoWS-t ws) 1) (ExpoWS-ing ws))]
        [else ws]))

; Player Structure, Room Structure, list of keys -> Player Stucture
; Moves the player according to the list of keys
(define (move-player player room lokey)
  (cond [(empty? lokey) player]
        [else (move-player (move-player-helper (first lokey) player room) room (rest lokey))]))

; key, Player Structure, Room structure -> Player Structure
; moves the player according to a single key
(define (move-player-helper key player room)
  (local [(define x (posn-x (Player-pos player)))
          (define y (posn-y (Player-pos player)))
          (define (update-player posn player lokey orn) (make-Player posn orn lokey))
          (define items (Room-items room))
          (define item (over-which-item player items))]
    (cond [(and (not (empty? items))
                (Item? item))
           (update-player (make-dependent-posn x y (Player-orn player) item) player empty (Player-orn player))]
          [(<= x 35) (update-player (make-posn (+ x SPEED) y) player empty (Player-orn player))]
          [(>= x 665) (update-player (make-posn (- x SPEED) y) player empty (Player-orn player))]
          [(<= y 35) (update-player (make-posn x (+ y SPEED)) player empty (Player-orn player))]
          [(>= y 665) (update-player (make-posn x (- y SPEED)) player empty (Player-orn player))]
          [(string=? "w" key) (update-player (make-posn x (- y SPEED)) player (Player-lokey player) "up/down")]
          [(string=? "a" key) (update-player (make-posn (- x SPEED) y) player (Player-lokey player) "left/right")]
          [(string=? "s" key) (update-player (make-posn x (+ y SPEED)) player (Player-lokey player) "up/down")]
          [(string=? "d" key) (update-player (make-posn (+ x SPEED) y) player (Player-lokey player) "left/right")])))

; Player structure, list of Items -> Item structure
; returns the Item the character is over
; returns false if the charachter is not over an Item
(define (over-which-item player items)
  (local [(define x (posn-x (Player-pos player)))
          (define y (posn-y (Player-pos player)))
          (define (update-player posn player lokey orn) (make-Player posn orn lokey))]
    (cond [(empty? items) #false]
          [(and (string=? "plant" (Item-type (first items)))
                (and (<= (- (Item-x (first items)) (/ (image-width PLANT) 2))
                         x
                         (+ (Item-x (first items)) (/ (image-width PLANT) 2)))
                     (<= (- (Item-y (first items)) (/ (image-height PLANT) 2))
                         y
                         (+ (Item-y (first items)) (/ (image-height PLANT) 2)))))
           (first items)]
          [(and (string=? "diningtable" (Item-type (first items)))
                (and (<= (- (Item-x (first items)) (/ (image-width DININGTABLE) 2))
                         x
                         (+ (Item-x (first items)) (/ (image-width DININGTABLE) 2)))
                     (<= (- (Item-y (first items)) (/ (image-height DININGTABLE) 2))
                         y
                         (+ (Item-y (first items)) (/ (image-height DININGTABLE) 2)))))
           (first items)]
          [(and (string=? "sidetable" (Item-type (first items)))
                (and (<= (- (Item-x (first items)) (/ (image-width SIDETABLE) 2))
                         x
                         (+ (Item-x (first items)) (/ (image-width SIDETABLE) 2)))
                     (<= (- (Item-y (first items)) (/ (image-height SIDETABLE) 2))
                         y
                         (+ (Item-y (first items)) (/ (image-height SIDETABLE) 2)))))
           (first items)]
          [(and (string=? "buffettable" (Item-type (first items)))
                (and (<= (- (Item-x (first items)) (/ (image-width BUFFETTABLE) 2))
                         x
                         (+ (Item-x (first items)) (/ (image-width BUFFETTABLE) 2)))
                     (<= (- (Item-y (first items)) (/ (image-height BUFFETTABLE) 2))
                         y
                         (+ (Item-y (first items)) (/ (image-height BUFFETTABLE) 2)))))
           (first items)]
          [(and (string=? "fountain" (Item-type (first items)))
                (and (<= (- (Item-x (first items)) (/ (image-width FOUNTAIN) 2))
                         x
                         (+ (Item-x (first items)) (/ (image-width FOUNTAIN) 2)))
                     (<= (- (Item-y (first items)) (/ (image-height FOUNTAIN) 2))
                         y
                         (+ (Item-y (first items)) (/ (image-height FOUNTAIN) 2)))))
           (first items)]
          [(and (string=? "bed" (Item-type (first items)))
                (and (<= (- (Item-x (first items)) (/ (image-width BED) 2))
                         x
                         (+ (Item-x (first items)) (/ (image-width BED) 2)))
                     (<= (- (Item-y (first items)) (/ (image-height BED) 2))
                         y
                         (+ (Item-y (first items)) (/ (image-height BED) 2)))))
           (first items)]
          [(and (string=? "sofa" (Item-type (first items)))
                (and (<= (- (Item-x (first items)) (/ (image-width SOFA) 2))
                         x
                         (+ (Item-x (first items)) (/ (image-width SOFA) 2)))
                     (<= (- (Item-y (first items)) (/ (image-height SOFA) 2))
                         y
                         (+ (Item-y (first items)) (/ (image-height SOFA) 2)))))
           (first items)]
          [(and (string=? "upchair" (Item-type (first items)))
                (and (<= (- (Item-x (first items)) (/ (image-width UPCHAIR) 2))
                         x
                         (+ (Item-x (first items)) (/ (image-width UPCHAIR) 2)))
                     (<= (- (Item-y (first items)) (/ (image-height UPCHAIR) 2))
                         y
                         (+ (Item-y (first items)) (/ (image-height UPCHAIR) 2)))))
           (first items)]
          [(and (string=? "downchair" (Item-type (first items)))
                (and (<= (- (Item-x (first items)) (/ (image-width DOWNCHAIR) 2))
                         x
                         (+ (Item-x (first items)) (/ (image-width DOWNCHAIR) 2)))
                     (<= (- (Item-y (first items)) (/ (image-height DOWNCHAIR) 2))
                         y
                         (+ (Item-y (first items)) (/ (image-height DOWNCHAIR) 2)))))
           (first items)]
          [(and (string=? "leftchair" (Item-type (first items)))
                (and (<= (- (Item-x (first items)) (/ (image-width LEFTCHAIR) 2))
                         x
                         (+ (Item-x (first items)) (/ (image-width LEFTCHAIR) 2)))
                     (<= (- (Item-y (first items)) (/ (image-height LEFTCHAIR) 2))
                         y
                         (+ (Item-y (first items)) (/ (image-height LEFTCHAIR) 2)))))
           (first items)]
          [(and (string=? "rightchair" (Item-type (first items)))
                (and (<= (- (Item-x (first items)) (/ (image-width RIGHTCHAIR) 2))
                         x
                         (+ (Item-x (first items)) (/ (image-width RIGHTCHAIR) 2)))
                     (<= (- (Item-y (first items)) (/ (image-height RIGHTCHAIR) 2))
                         y
                         (+ (Item-y (first items)) (/ (image-height RIGHTCHAIR) 2)))))
           (first items)]
          [(and (string=? "sink" (Item-type (first items)))
                (and (<= (- (Item-x (first items)) (/ (image-width SINK) 2))
                         x
                         (+ (Item-x (first items)) (/ (image-width SINK) 2)))
                     (<= (- (Item-y (first items)) (/ (image-height SINK) 2))
                         y
                         (+ (Item-y (first items)) (/ (image-height SINK) 2)))))
           (first items)]
          [(and (string=? "toilet" (Item-type (first items)))
                (and (<= (- (Item-x (first items)) (/ (image-width TOILET) 2))
                         x
                         (+ (Item-x (first items)) (/ (image-width TOILET) 2)))
                     (<= (- (Item-y (first items)) (/ (image-height TOILET) 2))
                         y
                         (+ (Item-y (first items)) (/ (image-height TOILET) 2)))))
           (first items)]
          [(and (string=? "bathtub" (Item-type (first items)))
                (and (<= (- (Item-x (first items)) (/ (image-width BATHTUB) 2))
                         x
                         (+ (Item-x (first items)) (/ (image-width BATHTUB) 2)))
                     (<= (- (Item-y (first items)) (/ (image-height BATHTUB) 2))
                         y
                         (+ (Item-y (first items)) (/ (image-height BATHTUB) 2)))))
           (first items)]
          [else (over-which-item player (rest items))])))

; player x, player y, player orientation, list of items -> posn
; makes a new player x and y posn dependent on the players orientation and previous location
(define (make-dependent-posn x y orn item)
  (cond [(and (string=? orn "left/right")
              (< x (Item-x item)))
         (make-posn (- x SPEED) y)]
        [(and (string=? orn "left/right")
              (> x (Item-x item)))
         (make-posn (+ x SPEED) y)]
        [(and (string=? orn "up/down")
              (< y (Item-y item)))
         (make-posn x (- y SPEED))]
        [(and (string=? orn "up/down")
              (> y (Item-y item)))
         (make-posn x (+ y SPEED))]))

; Worldstate -> Worldstate
; Changes which room or page is displayed if the door is open and the player is near the door
; returns false if those conditons are not met
(define (change-room ws)
  (local [(define lod (Room-lod (WS-room ws)))
          (define player (WS-player ws))
          (define current-door (foldr (lambda (door acc)
                                                    (if (string=? (Door-pos door)
                                                                  (player-position player))
                                                        door acc)) (first lod) lod))
          (define newroom (foldr (lambda (room acc)
                                   (if (= (Door-nxt# current-door)
                                               (Room-rid room)) room acc))
                                 (first rooms)
                                 rooms))
          (define newpage (foldr (lambda (page acc) (if (= (Door-nxt# current-door)
                                                           (ExpoWS-page page)) page acc))
                                 (first pages)
                                 pages))]
    ; Is the player located near a door and is that door open
    (cond [(and (string=? (player-position player)
                          (Door-pos current-door))
                (and (Door-open? current-door)
                     (string=? (Door-nxttype current-door) "room")))
           (make-WS (cond [(string=? (player-position (WS-player ws)) "top")
                           (make-Player (make-posn 350 650) (Player-orn player) (Player-lokey player))]
                          [(string=? (player-position (WS-player ws)) "bottom")
                           (make-Player (make-posn 350 50) (Player-orn player) (Player-lokey player))]
                          [(string=? (player-position (WS-player ws)) "left")
                           (make-Player (make-posn 650 350) (Player-orn player) (Player-lokey player))]
                          [(string=? (player-position (WS-player ws)) "right")
                           (make-Player (make-posn 50 350) (Player-orn player) (Player-lokey player))])
                    newroom
                    (WS-levelkeys ws)
                    (WS-have-ing? ws)
                    (WS-display-keys? ws))]
          [(and (and (string=? (player-position player))
                     (Door-open? current-door))
                (and (string=? (Door-nxttype current-door) "page")
                     (WS-have-ing? ws)))
           newpage]
          [else #false])))

; Worldstate, key -> Worldstate
; updates the worldstate when a key is pressed
(define (key-handler ws key)
  (cond [(WS? ws)
         (make-WS (handle-movement (WS-player ws) key)
                  (make-Room (Room-rid (WS-room ws))
                             (Room-keys (WS-room ws))
                             (open-door ws (Room-lod (WS-room ws)) key)
                             (Room-low (WS-room ws))
                             (Room-ing (WS-room ws))
                             (Room-items (WS-room ws)))
                  (take-key (WS-player ws) (WS-levelkeys ws) (Room-keys (WS-room ws)) key)
                  (take-ing ws (WS-player ws) (Room-ing (WS-room ws)) key)
                  (yes-display-keys key ws))]
        [(not (Trollstate? ws)) (next-page ws key)]
        [else ws]))

; key, worldstate -> worldstate
; displays on screen the keys the player has collected
(define (yes-display-keys key ws)
  (if (string=? "q" key) #true #false))

; Player structure, Key -> Worldstate
; updates the current list of keys (lokey) in the Player structure
(define (handle-movement player key)
  (if (or (string=? key "w") (string=? key "a")
          (string=? key "s") (string=? key "d"))
      (make-Player (Player-pos player)
                   (Player-orn player)
                   (cons key (remove key (Player-lokey player))))
      player))

; Player, list of keys, key -> list of keys
; takes the key if the player is near it
;[id x y have?]
(define (take-key player levelkeys keys key)
  (if (string=? "e" key)
      (map (lambda (levelkey) (local [(define keymatch (keyvkey levelkey keys))]
                                (if (and (not (boolean? keymatch))
                                         (and (<= (- (Key-x keymatch) 75) (posn-x (Player-pos player)) (+ (Key-x keymatch) 75))
                                              (<= (- (Key-y keymatch) 75) (posn-y (Player-pos player)) (+ (Key-y keymatch) 75))))
                                    (make-Levelkey
                                     (Levelkey-id levelkey)
                                     #true)
                                    levelkey))) levelkeys)
      levelkeys))

; Worldstate, Player structure, Ing structure, key -> boolean
; returns #true if the character picks up an ingredient
(define (take-ing ws player ing key)
  (if (string=? "e" key)
      (if (and (Ing? ing)
               (and (<= (- (Ing-x ing) 50) (posn-x (Player-pos player)) (+ (Ing-x ing) 50))
                    (<= (- (Ing-y ing) 50) (posn-y (Player-pos player)) (+ (Ing-y ing) 50))))
          #true
          (WS-have-ing? ws))
      (WS-have-ing? ws)))

; worldstate, key -> list of Doors
; opens the door if a player is near it and they have the key
;[id pos locked? open? nxt# nxttype]
(define (open-door ws lod key)
  (local [(define levelkeys (WS-levelkeys ws))
          (define player (WS-player ws))]
    (if (string=? key "e")
        (cond [(empty? lod) empty]
              [(and (key-for-door levelkeys (first lod))
                    (string=? (Door-pos (first lod)) (player-position player)))
               (cons (make-Door (Door-id (first lod))
                                (Door-pos (first lod))
                                #false
                                (if (Door-open? (first lod)) #false #true)
                                (Door-nxt# (first lod))
                                (Door-nxttype (first lod)))
                     (open-door ws (rest lod) key))]
              [else (cons (first lod) (open-door ws (rest lod) key))])
        lod)))

; Player -> string
; produces a string--top, bottom, left, right--determind by the player's x and y
(define (player-position player)
  (cond [(and (>= (posn-x (Player-pos player)) 600)
              (<= 300 (posn-y (Player-pos player)) 400))
         "right"]
        [(and (<= (posn-x (Player-pos player)) 100)
              (<= 300 (posn-y (Player-pos player)) 400))
         "left"]
        [(and (<= 300 (posn-x (Player-pos player)) 400)
              (<= (posn-y (Player-pos player)) 100))
         "top"]
        [(and (<= 300 (posn-x (Player-pos player)) 400)
              (>= (posn-y (Player-pos player)) 600))
         "bottom"]
        [else "center"]))
;(check-expect (player-position (make-Player (make-posn 640 350) "left/right" empty)) "right") 

; list of Levelkeys, door -> Key
; returns the key for the door
(define (key-for-door levelkeys door)
  (not (empty? (filter (lambda (levelkey)
                         (and (string=? (Levelkey-id levelkey) (Door-id door))
                              (Levelkey-have? levelkey)))
                       levelkeys))))
;(check-expect (key-for-door (list (make-Levelkey "blue" #true) (make-Levelkey "yellow" #false)) (make-Door "yellow" "top" #true #false 1.2 "room")) #false)

; Worldstate, key -> Worldstate
; removes the released key from Player-lokey
; [pos lives orn lokey]
(define (key-release-handler ws key)
  (if (WS? ws)
      (local [(define (remove-key key player) (make-Player (Player-pos player)
                                                           (Player-orn player)
                                                           (remove key (Player-lokey player))))]
        (make-WS (remove-key key (WS-player ws))
                 (WS-room ws)
                 (WS-levelkeys ws)
                 (WS-have-ing? ws)
                 #false))
      ws))

; Worldstate -> Worldstate
; Moves to the next page of the ExpoWS
(define (next-page ws key)
  (local [(define nextpage (filter (lambda (li) (= (+ 0.1 (ExpoWS-page ws)) (ExpoWS-page li))) pages))
          (define nextroom (foldr (lambda (li acc) (if (= (+ 0.1 (floor (ExpoWS-page ws))) (Room-rid li)) li acc)) #false rooms))]
    (if (string=? key "\r")
        (cond [(and (ExpoWS? ws) (= (ExpoWS-page ws) 4.1))
               initialtrollstate]
              [(empty? nextpage)
               (make-WS (WS-player initial-ws)
                        nextroom
                        (cond [(= (floor (Room-rid nextroom)) 1) level1keys]
                              [(= (floor (Room-rid nextroom)) 2) level2keys]
                              [(= (floor (Room-rid nextroom)) 3) level3keys])
                        #false
                        #false)]
              [else (first nextpage)])
        ws)))

; Worldstate -> boolean
; ends the game after page 4.3 is run
(define (end-here ws)
  (and (and (ExpoWS? ws) (= (ExpoWS-page ws) 4.3)) (= (ExpoWS-t ws) 0)))

;[player lor levelkeys have-ing?]
(define initial-expows page1.1) ; start with this | the rest are for testing or switching purposes
(define initial-ws (make-WS (make-Player (make-posn 350 350) "up/down" empty) (first rooms) (first level1keys) #false #false))
(define testlevel2 (make-WS (make-Player (make-posn 350 350) "up/down" empty) room2.1 (map (lambda (li) (make-Levelkey (Levelkey-id li) #true)) level2keys) #false #false))
(define testlevel3 (make-WS (make-Player (make-posn 350 350) "up/down" empty) room3.1 (map (lambda (li) (make-Levelkey (Levelkey-id li) #true)) level3keys) #false #false))
(define initialtrollstate (make-Trollstate 120))

(big-bang initial-expows
  (on-draw render)
  (on-tick tock)
  (on-key key-handler)
  (on-release key-release-handler)
  (stop-when end-here)
  (close-on-stop #true))
