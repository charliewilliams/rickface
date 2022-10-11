//
//  Face.swift
//  Rickface
//
//  Created by Charlie Williams on 02/10/2022.
//

import UIKit

let emotions = ["Adventurous", "Angry", "Annoyed", "Apathetic", "Ashamed", "Awfully Eager", "Belatedly remorseful", "Bemused", "Bereft", "Bilious", "Bored", "Brave", "Cheery", "Childlike", "Clever", "Confident", "Cool", "Crushed", "Daring", "Deathly", "Depressed", "Desperate", "Devastated", "Disappointed", "Disgusted", "Divine", "Drunk", "Empathetic", "Empowered", "Envious", "Excited", "Exhausted", "Extraneous", "Fairly Perturbed", "Fearful", "Fearless", "Flippant", "Floppy", "Freaky", "Frisky", "Frustrated", "Gleeful", "Great", "Guilty", "Happy", "Haughty", "Heartbroken", "Honourable", "Hopeful", "Icy", "Indifferent", "Invincible", "Jealous", "Joyful", "Just Normal", "Livid", "Magnanimous", "Mesmerised", "Mildly Concerned", "Mindful", "Mischievous", "Misunderstood", "Neither-here-nor-there", "Nervous", "Nostalgic", "Numb", "OK", "Paralysed", "Paranoid", "Passionate", "Peeved", "Pensive", "Perfect", "Pious", "Pitiful", "Puzzled", "Quietly Euphoric", "Quite Good", "Quizzical", "Rather Cross", "REALLY ANGRY", "REALLY HAPPY", "Regretful", "REALLY SAD", "Rejected", "Resilient", "Sad", "Secretive", "Shocked", "Shy", "Skeptical", "Sleepy", "Somewhat disenchanted", "Soppy", "Spooked", "Starving", "Super-keen", "Surprised", "Sweetly Sorrowful", "Sympathetic", "Tense", "Terrified", "Tormented", "Torn", "Totally enraged", "Unhappy"]

extension Collection {
    
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct Face {
    
    public let emotion: String
    public let image: UIImage
    
    public static func random() -> Face! {
        
        var face: Face?
        
        while face == nil {
            face = Face(index: Int(arc4random_uniform(UInt32(emotions.count))))
        }
        return face
    }
    
    public init?(index: Int) {
        
        guard let emotion = emotions[safe: index],
              let image = UIImage(named: String(format: "%03d", index + 1)) else {
            return nil
        }
        
        self.emotion = emotion
        self.image = image
    }
}
